import { defineConfig } from 'astro/config';
import { execSync } from 'node:child_process';
import mdx from '@astrojs/mdx';

// Build stamp: the commit this build came from. Vercel sets
// VERCEL_GIT_COMMIT_SHA at build time; locally ask git. BaseHead.astro writes
// it as <meta name="build-commit">, and `test.sh --live` compares it with
// origin/main, so production lagging the repo is a failure, not a surprise.
const buildCommit = process.env.VERCEL_GIT_COMMIT_SHA
	|| (() => {
		try { return execSync('git rev-parse HEAD', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); }
		catch { return ''; }
	})();

import sitemap from '@astrojs/sitemap';

import { unified } from '@astrojs/markdown-remark';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';

// https://astro.build/config
export default defineConfig({
	site: 'https://padj.vercel.app',
	integrations: [
		mdx(),
		sitemap({
			// Unlisted pages: /press and /software are unfinished (kept, not
			// promoted); /qr is a utility page for sharing the site in person.
			filter: (page) => !/\/(press|software|qr)\/$/.test(page),
		}),
	],
	markdown: {
		processor: unified({
			remarkPlugins: [remarkMath],
			rehypePlugins: [rehypeKatex]
		})
	},
	vite: {
		define: { __BUILD_COMMIT__: JSON.stringify(buildCommit) },
	},
});
