---
title: "Raspberry Pi 5 Kit"
description: "CanaKit Raspberry Pi 5 unboxing and hardware setup - a 4GB development board with active cooling and essential accessories"
techStack: ["Raspberry Pi", "Linux", "Hardware", "ARM"]
keyFeatures: [
  "Raspberry Pi 5 with 4GB RAM and Broadcom BCM2712 quad-core ARM Cortex-A76",
  "Official Raspberry Pi Active Cooler with aluminum heatsink and PWM-controlled fan",
  "CanaKit protective case designed for Pi 5 with ventilation",
  "45W USB-C power supply for stable power delivery under load",
  "USB microSD card reader for flashing OS images"
]
technicalHighlights: [
  "Dual 4Kp60 HDMI output via micro-HDMI ports",
  "Gigabit Ethernet and dual-band WiFi 5 connectivity",
  "40-pin GPIO header for hardware projects and HATs",
  "USB 3.0 ports for high-speed peripheral connections",
  "PCIe 2.0 x1 connector for NVMe storage expansion"
]
impact: "First hardware project documented on this site. The Pi 5 serves as a flexible platform for embedded Linux development, home automation, and self-hosted services."
tags: ["raspberry-pi", "linux", "arm", "hardware", "embedded", "canakit", "single-board-computer"]
status: "active"
order: 2
heroImage: "/projects/raspberry-pi-5/kit-overview.jpg"
images: [
  "/projects/raspberry-pi-5/kit-overview.jpg",
  "/projects/raspberry-pi-5/pi5-board-top.jpg",
  "/projects/raspberry-pi-5/active-cooler.jpg",
  "/projects/raspberry-pi-5/gpio-reference.jpg"
]
---

I picked up a CanaKit Raspberry Pi 5 to have a dedicated Linux box for tinkering, running local services, and hardware experiments. This is the 4GB variant—enough for most headless workloads without the premium of the 8GB model.

## What's in the Kit

The CanaKit bundle includes everything needed to get started:

- **Raspberry Pi 5 (4GB)** — The board itself, featuring a Broadcom BCM2712 SoC with four ARM Cortex-A76 cores at 2.4GHz
- **Official Raspberry Pi Active Cooler** — Aluminum heatsink with integrated fan, connects via the dedicated fan header for PWM speed control
- **CanaKit Case** — Black enclosure with cutouts for all ports and ventilation slots
- **45W USB-C Power Supply** — Delivers up to 5A at 5V, necessary for the Pi 5's increased power requirements
- **Micro-HDMI Cable** — For connecting to displays (Pi 5 uses micro-HDMI, not full-size)
- **USB MicroSD Card Reader** — For flashing Raspberry Pi OS or other distributions
- **GPIO Quick Reference Card** — Handy pinout diagram for the 40-pin header

## Why Pi 5 Over Earlier Models

The Pi 5 is a meaningful upgrade from the Pi 4:

- **2-3x faster CPU** — The A76 cores are substantially more capable than the A72s in the Pi 4
- **Native PCIe** — Can add NVMe storage without USB bottlenecks
- **Better thermals support** — Dedicated fan connector with PWM control
- **Real-time clock header** — For accurate timekeeping without network
- **Power button** — Finally, a proper on/off button

## Current Status

Kit unboxed, hardware on the bench. Next steps: flash an OS, attach the active cooler, and set up as a headless server.
