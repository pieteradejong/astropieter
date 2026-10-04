---
title: "Chrome Bookmark Assistant"
description: "A Chrome extension that finds broken bookmarks without flagging every login page and bot wall as dead"
techStack: ["JavaScript", "Chrome Extensions (Manifest V3)", "Jest"]
keyFeatures: [
  "Checks every bookmark and sorts the results into broken, login-required and available",
  "Scheduled background scans, with a toolbar badge when something new breaks",
  "Review results in the popup and delete bookmarks one at a time or in bulk"
]
technicalHighlights: [
  "Only 404, 410 and DNS failures count as broken; 401, 403, 429 and LinkedIn's 999 are treated as login walls, not dead links",
  "Runs in a Manifest V3 service worker, with scans scheduled through the alarms API",
  "Jest tests for the checker, scanner and tagger"
]
impact: "A naive link checker reports half of a bookmark list as broken. Telling a dead link from a login wall is what makes the result usable."
tags: ["browser-extension", "productivity", "privacy"]
status: "active"
order: 5
hero: "../../assets/projects/chrome-bookmarks.jpg"
heroAlt: "Chrome Bookmark Assistant results: 1803 working, 92 needing review, 18 behind a login"
---

Started as a Python and React app that read Chrome's bookmarks file, then rebuilt as an extension so it can use the bookmarks API directly and run on a schedule. Everything runs locally in the browser. The source is private for now.
