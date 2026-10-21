#!/usr/bin/env bash
# ponytail: compose the Pages site — marketing landing at /, the app at /app
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf dist
npx vite build --base=/app/ --outDir=dist/app
cp -R landing/. dist/
# The App Store listing links /privacy.html; without this copy Pages falls back to the landing page.
cp dist/app/privacy.html dist/privacy.html
echo "built dist/ (landing at /, app at /app)"
