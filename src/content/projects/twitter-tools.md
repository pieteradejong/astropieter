---
title: "Twitter Tools"
description: "Search, sort and track my own Twitter/X history from the archive export, offline, with topic tagging by sentence embeddings"
techStack: ["Python", "FastAPI", "SQLite", "Sentence Transformers", "React", "TypeScript", "Tailwind CSS"]
githubUrl: "https://github.com/pieteradejong/twittertools"
keyFeatures: [
  "Runs entirely offline from the X archive export; no API credentials needed",
  "Full-text keyword search over liked tweets (SQLite FTS5)",
  "Follower gains and losses between successive archive snapshots",
  "Topic tagging of tweets and suggested lists for accounts I follow"
]
technicalHighlights: [
  "Every archive export, folder or zip, loads into one database as a dated snapshot; follow changes are SQL views",
  "Zero-shot, multi-label topic classification: tweets are matched against seed phrases by cosine similarity, with no training data",
  "The X API is used only to fill in what the archive leaves out, such as bios and follower counts",
  "66 unit tests that run offline"
]
impact: "Turns a pile of export files into something searchable, and answers \"who unfollowed, and when\" without paying for API access."
tags: ["data-analysis", "nlp", "semantic-search", "sqlite"]
status: "active"
order: 3
hero: "../../assets/projects/twitter-tools.svg"
heroAlt: "Twitter Tools pipeline: X archive exports load into SQLite, served by FastAPI to a React UI, with optional X API enrichment and a topic tagger"
---

X lets you download your whole account as an archive, but the export is a folder of JavaScript files. This loads every export I have into SQLite, keeps each one as a dated snapshot, and puts a FastAPI backend and React front end on top for searching, filtering and tagging.
