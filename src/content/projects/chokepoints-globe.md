---
aiGenerated: true
title: "Chokepoints"
description: "An interactive globe of the sea and air networks that move physical goods, and the fourteen narrow passages they run through: close one and see which lanes reroute, which are delayed and which strand"
techStack: ["JavaScript", "three.js", "WebGL", "Python"]
githubUrl: "https://github.com/pieteradejong/chokepoints-globe"
demoUrl: "https://chokepoints-globe.vercel.app"
keyFeatures:
  [
    "Click any of fourteen chokepoints and close it: every affected lane recolours as rerouted, delayed or stranded, stranded vessels stop, and the alternative route draws itself where one exists",
    "Three networks with their own logic: containers (distance and schedule), energy and bulk (draft and politics), air corridors (topology only)",
    "Runs from one HTML file with three.js vendored: no build, no network requests, works offline",
  ]
technicalHighlights:
  [
    "Sea lanes are chains of named waypoints, with only each leg interpolated as a great circle, so Shanghai–Rotterdam goes through Malacca and Suez instead of over Siberia",
    "A Python check samples every leg at 60 points against the same Natural Earth coastline the browser renders; it found 33 routes crossing land on its first pass and now reports 711 legs across 78 lanes, 0 crossing",
    "Closure results are not hand-authored: they follow from the lane data and three rules (detour, ports reachable only through the passage, draft limits)",
    "The Natural Earth 110m coastline is simplified to 2,134 points and delta-encoded to about 15 KB inline",
  ]
impact: "Closing Hormuz strands 100% of its 8 lanes; closing Malacca strands 7% of its 11 because Lombok absorbs the traffic, while closing Lombok strands 92% because the ships using it don't fit through Malacca."
tags: ["visualization", "three.js", "webgl", "geography", "logistics"]
status: "completed"
startDate: "2026-08"
heroAlt: "The globe centred on the Persian Gulf with the Strait of Hormuz closed: Gulf lanes drawn in red and a card reading 100% stranded, no alternative"
hero: "../../assets/projects/chokepoints-globe.png"
syncedFrom: "chokepoints-globe@6e2f99ff1af2d7088354d6b68a34556edbb8427b"
---

A model of world shipping, energy and air traffic built around one question: at a chokepoint,
can anything substitute for it? Lane count measures volume; whether a detour exists, and whether
the ships can use it, decides what a closure does.

The vessels are not real. There is no AIS feed and no flight schedule data. Lane weights are
order-of-magnitude judgements that drive line brightness and vessel counts. The coastline, the
port coordinates, the chokepoint geography and the routing structure are real.
