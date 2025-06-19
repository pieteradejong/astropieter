---
title: 'Blog Series: Example Post'
description: 'This is an example of a blog post in draft mode for a series.'
pubDate: 'Jan 15, 2024'
tags: ['writing', 'meta']
draft: true
---

# My Blog Series: Part 1

This is an example blog post that's currently in draft mode. You can write your entire blog series with `draft: true` in the frontmatter, and they'll only be visible during development.

## How the Draft System Works

- **In Development**: All posts (draft and published) are visible when you run `npm run dev`
- **In Production**: Only posts with `draft: false` (or no draft field) are visible on the live site
- **Draft Badge**: Draft posts show a yellow "DRAFT" badge during development

## Publishing a Post

When you're ready to publish, simply change:
```yaml
draft: true
```

To:
```yaml
draft: false
```

Or remove the `draft` field entirely (it defaults to `false`).

## Writing Your Series

You can now confidently write your entire blog series knowing that:
1. Posts won't appear on your live site until you mark them as published
2. You can preview them locally during development
3. Each post maintains its own publish status independently 