#!/bin/bash

echo "Building production bundle..."

# Build frontend
echo "Building frontend with Vite..."
npm run build

# Build backend using production entry point (no Vite dependencies)
echo "Building backend with esbuild..."
npx esbuild server/production-entry.ts \
  --platform=node \
  --packages=external \
  --bundle \
  --format=esm \
  --outdir=dist \
  --outfile=dist/server.js \
  --define:process.env.NODE_ENV=\"production\"

echo "Production build complete!"
echo "Backend: dist/server.js"
echo "Frontend: dist/"