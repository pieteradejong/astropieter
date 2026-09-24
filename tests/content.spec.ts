import { test, expect, type Page } from '@playwright/test';

// Content rendering in a real browser. The markup checks in test.sh prove
// KaTeX *ran*; these prove the result is what a reader sees: the stylesheet
// and fonts load, the MathML fallback is hidden, and nothing overflows.
//
// Fixtures are draft posts (src/content/blog/test-fixture-*), served in dev
// and never built for production.

const MD_FIXTURE = '/blog/test-fixture-markdown/';
const MDX_FIXTURE = '/blog/test-fixture-mdx/';

// Collect console errors and failed requests, so a blocked stylesheet (bad
// SRI hash, CDN 404) fails the test instead of silently unstyling the math.
async function openClean(page: Page, path: string) {
	const problems: string[] = [];
	page.on('console', (m) => {
		if (m.type() === 'error') problems.push(`console: ${m.text()}`);
	});
	page.on('pageerror', (e) => problems.push(`pageerror: ${e.message}`));
	page.on('response', (r) => {
		if (r.status() >= 400) problems.push(`${r.status()} ${r.url()}`);
	});
	page.on('requestfailed', (r) => problems.push(`failed: ${r.url()}`));
	// networkidle: on a cold dev server Vite optimizes deps on first load and
	// reloads the page, which would destroy the context under an assertion.
	const res = await page.goto(path, { waitUntil: 'networkidle' });
	expect(res?.status(), `GET ${path}`).toBe(200);
	await page.evaluate(() => document.fonts.ready);
	return problems;
}

// Visible text outside code blocks. Raw `$$` or `\frac` here means math
// leaked through unrendered.
const proseText = (page: Page) =>
	page.locator('article').first().evaluate((el) => {
		const clone = el.cloneNode(true) as HTMLElement;
		clone.querySelectorAll('pre, code, .katex').forEach((n) => n.remove());
		return clone.innerText;
	});

test.describe('Markdown fixture', () => {
	test('renders every Markdown and GFM construct', async ({ page }) => {
		const problems = await openClean(page, MD_FIXTURE);
		const a = page.locator('article').first();

		await expect(a.locator('h2#second-level-heading')).toHaveText('Second-level heading');
		await expect(a.locator('h3#third-level-heading')).toHaveText('Third-level heading');
		await expect(a.locator('strong', { hasText: 'bold' })).toHaveCount(1);
		await expect(a.locator('em', { hasText: 'italic' })).toHaveCount(1);
		await expect(a.locator('del', { hasText: 'strikethrough' })).toHaveCount(1);
		await expect(a.locator('p code', { hasText: 'inline code' })).toHaveCount(1);
		await expect(a.locator('a[href="/about/"]')).toHaveText('relative link');
		await expect(a.locator('a[href="https://example.com"]')).toHaveCount(1);
		await expect(a.locator('ul ul li', { hasText: 'nested item' })).toHaveCount(1);
		await expect(a.locator('ol:not([data-footnotes] ol) > li')).toHaveCount(2); // footnotes are an <ol> too
		await expect(a.locator('input[type="checkbox"]')).toHaveCount(2);
		await expect(a.locator('input[type="checkbox"]:checked')).toHaveCount(1);
		await expect(a.locator('blockquote')).toContainText('A blockquote.');
		await expect(a.locator('table tbody tr')).toHaveCount(2);
		await expect(a.locator('table th').nth(1)).toHaveCSS('text-align', /right$/); // Chrome reports align="right" as -webkit-right
		await expect(a.locator('hr')).not.toHaveCount(0);
		await expect(a.locator('img[alt="Fixture image alt text"]')).toBeVisible();
		await expect(a.locator('[data-footnote-ref]')).toHaveCount(1);
		await expect(a.locator('[data-footnotes]')).toContainText('The footnote text.');
		expect(problems).toEqual([]);
	});

	test('highlights fenced code and leaves $$ inside it alone', async ({ page }) => {
		await openClean(page, MD_FIXTURE);
		const pre = page.locator('article pre.astro-code').first();
		await expect(pre).toContainText('def entropy(p):');
		await expect(pre).toContainText('# $$ not math in code');
		await expect(pre.locator('.katex')).toHaveCount(0);
		// Shiki colours tokens with inline styles; plain text would have none.
		expect(await pre.locator('span[style*="color"]').count()).toBeGreaterThan(3);
	});

	test('renders inline and display math with no errors', async ({ page }) => {
		const problems = await openClean(page, MD_FIXTURE);
		const a = page.locator('article').first();
		await expect(a.locator('.katex-display')).toHaveCount(3);
		await expect(a.locator('.katex')).toHaveCount(4); // 3 display + 1 inline
		await expect(a.locator('p > .katex')).toHaveCount(1); // the inline one sits in its sentence
		await expect(a.locator('.katex-error')).toHaveCount(0);
		await expect(a.locator('.katex .katex-mathml math')).toHaveCount(4); // screen-reader MathML
		await expect(a.locator('.katex-display .mtable, .katex-display .delimsizing').first()).toBeAttached(); // matrix
		const prose = await proseText(page);
		expect(prose).toContain('it costs $5.'); // escaped dollar stays literal
		expect(prose).not.toMatch(/\$\$|\\frac|\\int|\\begin/);
		expect(problems).toEqual([]);
	});

	test('KaTeX stylesheet and fonts are applied', async ({ page }) => {
		const problems = await openClean(page, MD_FIXTURE);
		const katex = page.locator('article .katex').first();
		// Only katex.css sets this font; without the stylesheet it inherits the body font.
		expect(await katex.evaluate((el) => getComputedStyle(el).fontFamily)).toContain('KaTeX_Main');
		expect(await page.evaluate(() => document.fonts.check('16px KaTeX_Main'))).toBe(true);
		// Without the stylesheet the MathML copy is visible too and every formula shows twice.
		await expect(page.locator('article .katex-mathml').first()).toHaveCSS('position', 'absolute');
		await expect(page.locator('article .katex-display').first()).toHaveCSS('text-align', 'center');
		expect(problems).toEqual([]);
	});

	test('no horizontal page overflow at phone width', async ({ page }) => {
		await page.setViewportSize({ width: 375, height: 800 });
		await openClean(page, MD_FIXTURE);
		const { scroll, client } = await page.evaluate(() => ({
			scroll: document.documentElement.scrollWidth,
			client: document.documentElement.clientWidth,
		}));
		expect(scroll, 'page is wider than the viewport').toBeLessThanOrEqual(client);
	});
});

test.describe('MDX fixture', () => {
	test('renders inline and display math in .mdx posts', async ({ page }) => {
		const problems = await openClean(page, MDX_FIXTURE);
		const a = page.locator('article').first();
		await expect(a.locator('.katex-display')).toHaveCount(1);
		await expect(a.locator('.katex')).toHaveCount(2);
		await expect(a.locator('.katex-error')).toHaveCount(0);
		expect(await a.locator('.katex').first().evaluate((el) => getComputedStyle(el).fontFamily)).toContain('KaTeX_Main');
		expect(await proseText(page)).not.toMatch(/\$\$|\\frac/);
		expect(problems).toEqual([]);
	});
});

test.describe('Every blog post', () => {
	test('renders cleanly: no math errors, no leaked LaTeX, no console errors', async ({ page }) => {
		// Read the index as HTML rather than a live page, so a dev-server reload
		// cannot interrupt it. In dev the index lists drafts too, so they get checked.
		const index = await (await page.request.get('/blog/')).text();
		const hrefs = [...new Set([...index.matchAll(/href="(\/blog\/[^/"]+\/?)"/g)].map((m) => m[1]))];
		expect(hrefs.length, 'no posts linked from /blog/').toBeGreaterThan(0);

		// Soft assertions: one run reports every broken post, not just the first.
		for (const href of hrefs) {
			const problems = await openClean(page, href);
			const a = page.locator('article').first();
			expect.soft(await a.locator('.katex-error').count(), `${href}: KaTeX parse error`).toBe(0);
			expect.soft(await proseText(page), `${href}: unrendered LaTeX in prose`).not.toMatch(/\$\$|\\frac|\\int|\\begin\{/);
			// (Single-line `$$x$$`, which renders inline, is caught from the source
			// in test.sh: the HTML cannot tell it apart from intended `$x$`.)
			expect.soft(problems, `${href}: console or network errors`).toEqual([]);
			page.removeAllListeners();
		}
	});
});
