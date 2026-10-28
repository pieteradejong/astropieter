#!/usr/bin/env node
// prose-blocks.mjs <label> [--footer] < page.html
//
// Prints one line per block of visible prose in the page's <main> (or its
// <footer> with --footer): "<label>\t<sha256>\t<first 40 chars>". test.sh
// compares these lines with tests/prose.sha256 (DECISIONS #25).
//
// Only the words count. Tags, classes and wrapper elements are dropped, so a
// markup or theme change keeps every hash and a wording change does not.

import { createHash } from 'node:crypto';

const label = process.argv[2];
const region = process.argv.includes('--footer') ? 'footer' : 'main';
if (!label) {
	console.error('usage: prose-blocks.mjs <label> [--footer] < page.html');
	process.exit(2);
}

// Block-level tags: each opening or closing one ends the current block.
const BLOCK = 'p|li|h[1-6]|blockquote|dt|dd|figcaption|td|th|div|section|article|header|ul|ol|dl|table|tr|form|label|button|br|hr';

const ENTITIES = {
	amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', copy: '©',
	mdash: '—', ndash: '–', hellip: '…', lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”',
};
const decode = (s) => s.replace(/&(#x[0-9a-f]+|#[0-9]+|[a-z]+);/gi, (m, e) => {
	if (e[0] === '#') {
		const n = e[1].toLowerCase() === 'x' ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
		return String.fromCodePoint(n);
	}
	return ENTITIES[e.toLowerCase()] ?? m;
});

let html = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (c) => { html += c; });
process.stdin.on('end', () => {
	const m = html.match(new RegExp(`<${region}[\\s>][\\s\\S]*?</${region}>`, 'i'));
	if (!m) {
		console.error(`prose-blocks: no <${region}> in the page for ${label}`);
		process.exit(1);
	}
	const blocks = m[0]
		.replace(/<!--[\s\S]*?-->/g, '')
		.replace(/<(script|style|svg|template|noscript)[\s>][\s\S]*?<\/\1>/gi, '')
		.replace(new RegExp(`</?(?:${BLOCK})(?:\\s[^>]*)?/?>`, 'gi'), '\n')
		// Inline tags become a space, so sibling links ("GitHub", "LinkedIn")
		// stay two words; the space before punctuation is taken back out.
		.replace(/<[^>]*>/g, ' ')
		.split('\n')
		.map((b) => decode(b).replace(/\s+/g, ' ').replace(/ ([.,;:!?)])/g, '$1').trim())
		// The footer's copyright year is the build year; it is not prose.
		.map((b) => b.replace(/© \d{4}/, '© YEAR'))
		.filter(Boolean);
	for (const b of blocks) {
		const sha = createHash('sha256').update(b).digest('hex');
		console.log(`${label}\t${sha}\t${b.slice(0, 40)}`);
	}
});
