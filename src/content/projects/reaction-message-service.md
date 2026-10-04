---
title: "Live Emoji Reactions"
description: "Fans send emoji reactions during a game; Kafka and Spark count them in 2-second windows, and the totals stream back to every viewer"
techStack: ["Go", "Apache Kafka", "Apache Spark", "Server-Sent Events", "Docker Compose"]
githubUrl: "https://github.com/pieteradejong/go-service"
keyFeatures: [
  "A Go service accepts reactions over HTTP and writes them to Kafka",
  "Spark Structured Streaming counts each emoji per 2-second window",
  "A second Go service reads the counts and pushes them to browsers over Server-Sent Events",
  "A Python script simulates a crowd of users for load"
]
technicalHighlights: [
  "Kafka writes retry with exponential backoff plus random jitter",
  "Reactions are keyed by emoji, so each emoji's events stay in order within a partition",
  "Docker Compose brings up ZooKeeper, Kafka, Spark and both services"
]
impact: "A small, complete streaming pipeline built to learn Go and Kafka: ingest, windowed aggregation, and fan-out to live clients."
tags: ["distributed-systems", "event-driven", "streaming", "go", "kafka"]
status: "completed"
order: 4
hero: "../../assets/projects/reaction-message-service.svg"
heroAlt: "Live Emoji Reactions pipeline: a Go service writes reactions to Kafka, Spark counts them in 2-second windows, and a Go broadcaster streams totals to viewers over SSE"
---

Picture a stadium screen showing how the crowd feels in real time. Reactions go in through one Go service, Spark tallies them every two seconds, and a second Go service broadcasts the running counts to anyone watching.
