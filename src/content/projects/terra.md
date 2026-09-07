---
title: "Terra"
description: "Real-time, physically-shaded Earth in Three.js with submarine cables, sea lanes, chokepoints and live aircraft/vessel/earthquake feeds"
techStack: ["Three.js", "GLSL", "WebGL", "Python", "FastAPI"]
githubUrl: "https://github.com/pieteradejong/terra"
demoUrl: "/terra/"
keyFeatures: [
  "Day/night terminator computed from the real UTC clock; Moon placed by a lunar ephemeris so its phase is correct",
  "Ray-marched Rayleigh + Mie atmospheric scattering with aerial perspective on the surface",
  "484 submarine cables with hover details, 16 major sea lanes, 17 chokepoints with EIA flow figures",
  "Live aircraft (OpenSky), vessels (AISStream) and earthquakes (USGS) when run with the local feed server"
]
technicalHighlights: [
  "Custom GLSL surface shader: normal-mapped relief, ocean glint, cloud shadows, city lights through twilight",
  "HDR pipeline: half-float MSAA target, soft-threshold bloom, ACES tonemapping",
  "Single self-contained HTML file with textures and geodata embedded",
  "FastAPI server merges three public feeds into one snapshot endpoint the page polls"
]
impact: "A situational-awareness globe built from public data: where the internet physically runs, where seaborne trade squeezes, and what is moving right now."
tags: ["three.js", "webgl", "shaders", "geospatial", "visualization", "infrastructure"]
status: "active"
---

A real-time model of Earth with the world's physical infrastructure drawn on top. The planet itself is shaded from physics — a ray-marched atmosphere gives the blue limb and the red terminator — and the layers above it come from public data: TeleGeography's cable map, EIA chokepoint flows, and, in local mode, live aircraft, ship and earthquake feeds.
