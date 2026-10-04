---
title: "TV Show Chat"
description: "Ask plain-English questions about all 144 episodes of Buffy the Vampire Slayer, answered by semantic search over episode embeddings"
techStack: ["Python", "FastAPI", "ChromaDB", "Sentence Transformers", "React", "TypeScript"]
githubUrl: "https://github.com/pieteradejong/tvshowchat"
keyFeatures: [
  "Natural-language search across all 7 seasons and 144 episodes",
  "Series timeline and per-character views alongside the search results",
  "A chat interface, still a prototype, on top of the search API"
]
technicalHighlights: [
  "Episode data crawled from buffy.fandom.com into a file-based document store, which stays the canonical copy",
  "ChromaDB is rebuilt from that store on first startup; it replaced an earlier Redis vector index",
  "Embeddings from all-MiniLM-L6-v2 (384 dimensions), loaded only when first needed",
  "The test script checks that the document store and ChromaDB agree on the episode count"
]
impact: "Retrieval over a small, closed corpus that many people know well, so a wrong answer is easy to spot."
tags: ["semantic-search", "vector-embeddings", "nlp", "data-pipeline"]
status: "active"
order: 2
hero: "../../assets/projects/tv-show-chat.svg"
heroAlt: "TV Show Chat pipeline: episode pages are crawled into a document store, embedded, and indexed in ChromaDB; each question is embedded and matched against that index"
---

Ask about a plot point and get the matching episodes back, ranked by similarity. The pipeline crawls episode pages, stores each one as a document, embeds it, and serves similarity search through a FastAPI backend to a React front end.
