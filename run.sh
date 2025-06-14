#!/bin/sh
# Run this script to start the Astro project locally
# Installs dependencies if needed, then starts the dev server on all interfaces

set -e

if [ ! -d node_modules ]; then
  echo "Installing dependencies..."
  npm install
fi

echo "Starting Astro dev server on all interfaces (http://localhost:4321/)..."
npm run dev -- --host 