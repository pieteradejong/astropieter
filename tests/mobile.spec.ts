import { test, expect, type Page } from '@playwright/test';

// Mobile rendering in a real browser (DECISIONS.md #8). test.sh proves the
// right CSS ships; these prove a phone can use it: nothing wider than the
// viewport, links and buttons big enough to tap, inputs that do not trigger
// iOS zoom, a hamburger menu that opens, and Terra's HUD out of its own way.
//
// Runs against the dev server (test.sh) and, under --live, against production.
// Nothing here depends on draft fixtures, so every test applies to both.

const PHONES = [320, 375, 414];

// Every main route. Terra is a static page outside Astro with its own rules;
// its file path is used because the dev server does not resolve /terra/ to it.
const ROUTES = [
	'/',
	'/about/',
	'/blog/',
	'/blog/why-blog/',
	'/projects/',
	'/projects/terra/',
	'/contact/',
	'/reading/',
	'/qr/',
];

async function open(page: Page, path: string, width: number) {
	await page.setViewportSize({ width, height: 800 });
	const res = await page.goto(path, { waitUntil: 'networkidle' });
	expect(res?.status(), `GET ${path}`).toBe(200);
	await page.evaluate(() => document.fonts.ready);
}

// Page-level overflow, plus the first few elements that stick out past the
// viewport, so a failure names the culprit instead of just the symptom.
// Elements that are meant to scroll inside their own box are skipped.
const overflowReport = (page: Page) =>
	page.evaluate(() => {
		const vw = document.documentElement.clientWidth;
		const scroll = document.documentElement.scrollWidth;
		const scrollsItself = (el: Element) => {
			const o = getComputedStyle(el).overflowX;
			return o === 'auto' || o === 'scroll' || o === 'hidden' || o === 'clip';
		};
		const offenders: string[] = [];
		for (const el of Array.from(document.body.querySelectorAll('*'))) {
			if (offenders.length >= 5) break;
			if (el.closest('pre, table, .katex-display, [hidden]')) continue;
			if (el instanceof HTMLElement && !el.checkVisibility()) continue;
			const r = el.getBoundingClientRect();
			if (r.width === 0) continue;
			if (r.right > vw + 1 || r.left < -1) {
				// A scroll container may be wide; what matters is its content stays inside it.
				if (scrollsItself(el)) continue;
				const id = el.id ? `#${el.id}` : '';
				const cls = el.className && typeof el.className === 'string' ? `.${el.className.trim().split(/\s+/).join('.')}` : '';
				offenders.push(`${el.tagName.toLowerCase()}${id}${cls} right=${Math.round(r.right)} left=${Math.round(r.left)}`);
			}
		}
		return { vw, scroll, offenders };
	});

// Visible, tappable controls in the chrome of every page. Inline prose links
// are held to the WCAG 2.5.8 minimum (24px); nav, footer and form controls to
// the 44px that keeps thumbs happy.
const smallTargets = (page: Page, selector: string, min: number) =>
	page.locator(selector).evaluateAll((els, min) => {
		const bad: string[] = [];
		for (const el of els as HTMLElement[]) {
			if (el.getRootNode() !== document) continue; // Astro dev toolbar (shadow DOM)
			if (!el.checkVisibility()) continue; // hidden (e.g. closed menu)
			const r = el.getBoundingClientRect();
			if (r.width === 0 || r.height === 0) continue;
			if (r.height < min - 0.5) bad.push(`${el.tagName.toLowerCase()} "${(el.textContent || el.getAttribute('aria-label') || '').trim().slice(0, 30)}" h=${Math.round(r.height)}`);
		}
		return bad;
	}, min);

// Text smaller than 12px is unreadable on a phone; inputs under 16px make iOS zoom.
const smallText = (page: Page) =>
	page.evaluate(() => {
		const bad: string[] = [];
		const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
		const seen = new Set<Element>();
		let n: Node | null;
		while ((n = walker.nextNode())) {
			const el = n.parentElement;
			if (!el || seen.has(el) || !n.textContent?.trim()) continue;
			seen.add(el);
			if (el.closest('script, style, noscript, [hidden], .katex-mathml, .sr-only')) continue;
			if (!(el as HTMLElement).checkVisibility()) continue;
			const fs = parseFloat(getComputedStyle(el).fontSize);
			if (fs < 12) bad.push(`${el.tagName.toLowerCase()}.${el.className} ${fs}px "${n.textContent.trim().slice(0, 20)}"`);
		}
		return bad.slice(0, 8);
	});

test.describe('Mobile: every page fits a phone', () => {
	for (const route of ROUTES) {
		for (const width of PHONES) {
			test(`${route} at ${width}px`, async ({ page }) => {
				await open(page, route, width);
				const r = await overflowReport(page);
				expect(r.scroll, `page is wider than the viewport (${r.scroll} > ${r.vw})`).toBeLessThanOrEqual(r.vw);
				expect(r.offenders, 'elements past the right edge').toEqual([]);
				expect(await smallText(page), 'text under 12px').toEqual([]);
			});
		}
	}
});

test.describe('Mobile: tap targets and inputs', () => {
	for (const route of ROUTES) {
		test(`${route} at 375px`, async ({ page }) => {
			await open(page, route, 375);
			expect(await smallTargets(page, 'body > header a, body > header button, footer a, form button, .button-link', 44), 'chrome controls under 44px').toEqual([]);
			expect(await smallTargets(page, 'form input:not([type=hidden]), form textarea', 40), 'form fields under 40px').toEqual([]);
			expect(await smallTargets(page, 'main a', 24), 'links under 24px').toEqual([]);
			// Playwright locators pierce shadow DOM; skip the Astro dev toolbar's own controls.
			const fontSizes = await page.locator('input:not([type=hidden]), textarea, select').evaluateAll((els) =>
				(els as HTMLElement[]).filter((e) => e.getRootNode() === document).map((e) => parseFloat(getComputedStyle(e).fontSize)),
			);
			for (const fs of fontSizes) expect(fs, 'input font-size (iOS zooms under 16px)').toBeGreaterThanOrEqual(16);
		});
	}
});

test.describe('Mobile: navigation', () => {
	test('hamburger opens a menu of full-width links, Escape closes it and restores focus', async ({ page }) => {
		await open(page, '/', 375);
		const btn = page.locator('#hamburgerBtn');
		const menu = page.locator('#mainNav');
		await expect(btn).toBeVisible();
		await expect(menu).toBeHidden();
		const box = await btn.boundingBox();
		expect(box!.height).toBeGreaterThanOrEqual(44);
		expect(box!.width).toBeGreaterThanOrEqual(44);

		await btn.click();
		await expect(menu).toBeVisible();
		await expect(btn).toHaveAttribute('aria-expanded', 'true');
		const links = menu.locator('a');
		expect(await links.count()).toBeGreaterThanOrEqual(5);
		for (const a of await links.all()) {
			const b = await a.boundingBox();
			expect(b!.height, 'menu link height').toBeGreaterThanOrEqual(44);
			expect(b!.width, 'menu link spans the screen').toBeGreaterThanOrEqual(300);
		}
		// Focus moved into the menu; Escape brings it back to the button.
		expect(await page.evaluate(() => document.activeElement?.closest('#mainNav') !== null)).toBe(true);
		await page.keyboard.press('Escape');
		await expect(menu).toBeHidden();
		await expect(btn).toHaveAttribute('aria-expanded', 'false');
		expect(await page.evaluate(() => document.activeElement?.id)).toBe('hamburgerBtn');
	});

	test('the menu sits directly under the header', async ({ page }) => {
		await open(page, '/about/', 375);
		await page.locator('#hamburgerBtn').click();
		const header = await page.locator('body > header').boundingBox();
		const menu = await page.locator('#mainNav').boundingBox();
		expect(Math.abs(menu!.y - (header!.y + header!.height))).toBeLessThanOrEqual(2);
	});

	test('the name truncates instead of pushing the button off a 320px screen', async ({ page }) => {
		await open(page, '/projects/', 320);
		const btn = await page.locator('#hamburgerBtn').boundingBox();
		expect(btn!.x + btn!.width).toBeLessThanOrEqual(320);
		await expect(page.locator('.mobile-section-label')).toBeHidden();
	});

	for (const width of [768, 900, 1024]) {
		test(`horizontal nav at ${width}px shows every link without overflow`, async ({ page }) => {
			await open(page, '/', width);
			await expect(page.locator('#hamburgerBtn')).toBeHidden();
			const links = page.locator('#mainNav a');
			for (const a of await links.all()) await expect(a).toBeVisible();
			const r = await overflowReport(page);
			expect(r.offenders).toEqual([]);
			const nav = await page.locator('#mainNav').boundingBox();
			expect(nav!.x + nav!.width).toBeLessThanOrEqual(width);
		});
	}
});

test.describe('Mobile: Terra', () => {
	// The globe redraws every animation frame. With software WebGL on a CI
	// runner that starves the main thread and every click or bounding box takes
	// seconds, so the page's reduced-motion mode (a few redraws a second, no
	// auto orbit) is what these tests run under. slow() triples the timeout.
	test.beforeEach(async ({ page }) => {
		await page.emulateMedia({ reducedMotion: 'reduce' });
	});

	test('at 375px the layer panel is behind a Layers button and the card never covers the title', async ({ page }) => {
		test.slow();
		await open(page, '/terra/index.html', 375);
		const panel = page.locator('#panel');
		const toggle = page.locator('#panelToggle');
		await expect(panel).toBeHidden();
		await expect(toggle).toBeVisible();
		const tb = await toggle.boundingBox();
		expect(tb!.height).toBeGreaterThanOrEqual(44);
		expect(tb!.width).toBeGreaterThanOrEqual(44);
		await toggle.click();
		await expect(panel).toBeVisible();
		await expect(toggle).toHaveAttribute('aria-expanded', 'true');
		const pb = await panel.boundingBox();
		expect(pb!.x + pb!.width).toBeLessThanOrEqual(375);
		await toggle.click();
		await expect(panel).toBeHidden();

		// Show the chokepoint card the way a tap would, then check it is a bottom sheet.
		await page.evaluate(() => {
			const c = document.getElementById('card')!;
			c.innerHTML = '<button aria-label="Close">×</button><h2>Strait of Hormuz</h2><p>' + 'x '.repeat(200) + '</p>';
			c.hidden = false;
		});
		const card = await page.locator('#card').boundingBox();
		const title = await page.locator('#title').boundingBox();
		expect(card!.y, 'card starts below the title').toBeGreaterThanOrEqual(title!.y + title!.height);
		expect(card!.x + card!.width).toBeLessThanOrEqual(375);
		const close = await page.locator('#card button').boundingBox();
		expect(close!.height).toBeGreaterThanOrEqual(44);
		expect(await smallText(page)).toEqual([]);
	});

	test('at desktop width the panel is open and there is no Layers button', async ({ page }) => {
		await open(page, '/terra/index.html', 1280);
		await expect(page.locator('#panel')).toBeVisible();
		await expect(page.locator('#panelToggle')).toBeHidden();
	});
});
