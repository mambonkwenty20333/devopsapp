#!/bin/bash

echo "Building production bundle..."

# Build frontend
echo "Building frontend with Vite..."
npm run build

# Build backend with proper exclusions
echo "Building backend with esbuild..."
npx esbuild server/index.ts \
  --platform=node \
  --packages=external \
  --bundle \
  --format=esm \
  --outdir=dist \
  --external:vite \
  --external:@vitejs/plugin-react \
  --external:@replit/vite-plugin-runtime-error-modal \
  --external:@replit/vite-plugin-cartographer \
  --define:process.env.NODE_ENV=\"production\"

echo "Production build complete!"
echo "Backend: dist/index.js"
echo "Frontend: dist/public/"