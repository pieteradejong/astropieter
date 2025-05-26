import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
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
			.array(z.string()).nonempty("tags must have at least one item")
	}),
});

const projects = defineCollection({
	schema: z.object({
		title: z.string(),
		description: z.string(),
		// Project-specific fields
		techStack: z.array(z.string()),
		githubUrl: z.string().optional(),
		demoUrl: z.string().optional(),
		keyFeatures: z.array(z.string()),
		technicalHighlights: z.array(z.string()),
		impact: z.string(),
		tags: z.array(z.string()).nonempty("tags must have at least one item"),
		// Optional fields
		startDate: z.string().optional(),
		endDate: z.string().optional(),
		status: z.enum(['active', 'completed', 'archived']).default('active'),
	}),
});

const tag = defineCollection({
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

