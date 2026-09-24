import { existsSync } from 'node:fs';
import { defineConfig } from '@playwright/test';

// Browser tests for content rendering. They run against an already-running dev
// server (test.sh starts one on :4322) because Astro's dev server daemonizes,
// which Playwright's webServer option cannot manage.
//
// Uses an installed Chrome so no browser download is needed. The app bundle is
// not always at Playwright's default path, so look for it; CHROME_PATH
// overrides. With no Chrome found, Playwright falls back to its own Chromium
// (`npx playwright install chromium`).
const CHROME = [
	process.env.CHROME_PATH,
	'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
	'/Applications/Chrome.app/Contents/MacOS/Google Chrome',
	'/usr/bin/google-chrome',
].find((p): p is string => !!p && existsSync(p));

export default defineConfig({
	testDir: './tests',
	fullyParallel: true,
	retries: 0,
	reporter: 'list',
	use: {
		baseURL: process.env.BASE_URL ?? 'http://localhost:4322',
		headless: true,
		launchOptions: CHROME ? { executablePath: CHROME } : {},
	},
});
