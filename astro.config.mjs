import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';

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
	}
});
