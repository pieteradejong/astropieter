import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { glob } from 'astro/loaders';

const blog = defineCollection({
	loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/blog' }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
		// Transform string to Date object
		pubDate: z
			.string()
			.or(z.date())
			.transform((val) => new Date(val)),
		updatedDate: z
			.string()
			.optional()
			.transform((str) => (str ? new Date(str) : undefined)),
		tags: z
			.array(z.string()).nonempty("tags must have at least one item"),
		draft: z.boolean().optional().default(false),
		// Series functionality
		series: z.string().optional(),
		seriesOrder: z.number().optional(),
		seriesDescription: z.string().optional()
	}),
});

const projects = defineCollection({
	loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/projects' }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
		// Project-specific fields
		techStack: z.array(z.string()),
		githubUrl: z.string().optional(),
		demoUrl: z.string().optional(),
		deploymentUrl: z.string().optional(),
		keyFeatures: z.array(z.string()),
		technicalHighlights: z.array(z.string()),
		impact: z.string(),
		tags: z.array(z.string()).nonempty("tags must have at least one item"),
		// Optional fields
		startDate: z.string().optional(),
		endDate: z.string().optional(),
		status: z.enum(['active', 'completed', 'archived']).default('active'),
		order: z.number().optional(), // Display order (lower numbers appear first)
	}),
});

const tag = defineCollection({
	loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: './src/content/tag' }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
	}),
});

export const collections = {
	'blog': blog,
	'projects': projects,
	'tag': tag
};
