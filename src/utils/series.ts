import type { CollectionEntry } from 'astro:content';

export type BlogPost = CollectionEntry<'blog'>;

export interface SeriesInfo {
	currentIndex: number;
	totalPosts: number;
	previousPost?: BlogPost;
	nextPost?: BlogPost;
	allPosts: BlogPost[];
}

/**
 * Get all posts in a series, sorted by seriesOrder
 */
export function getSeriesPosts(posts: BlogPost[], seriesName: string): BlogPost[] {
	return posts
		.filter(post => post.data.series === seriesName)
		.sort((a, b) => {
			const orderA = a.data.seriesOrder ?? 0;
			const orderB = b.data.seriesOrder ?? 0;
			return orderA - orderB;
		});
}

/**
 * Get series navigation info for a specific post
 */
export function getSeriesInfo(posts: BlogPost[], currentPost: BlogPost): SeriesInfo | null {
	if (!currentPost.data.series) {
		return null;
	}

	const seriesPosts = getSeriesPosts(posts, currentPost.data.series);
	const currentIndex = seriesPosts.findIndex(post => post.slug === currentPost.slug);
	
	if (currentIndex === -1) {
		return null;
	}

	return {
		currentIndex,
		totalPosts: seriesPosts.length,
		previousPost: currentIndex > 0 ? seriesPosts[currentIndex - 1] : undefined,
		nextPost: currentIndex < seriesPosts.length - 1 ? seriesPosts[currentIndex + 1] : undefined,
		allPosts: seriesPosts
	};
}

/**
 * Get all unique series from posts
 */
export function getAllSeries(posts: BlogPost[]): Array<{name: string, description?: string, postCount: number}> {
	const seriesMap = new Map<string, {description?: string, postCount: number}>();
	
	posts.forEach(post => {
		if (post.data.series) {
			const existing = seriesMap.get(post.data.series);
			seriesMap.set(post.data.series, {
				description: existing?.description || post.data.seriesDescription,
				postCount: (existing?.postCount || 0) + 1
			});
		}
	});

	return Array.from(seriesMap.entries()).map(([name, info]) => ({
		name,
		...info
	}));
} 