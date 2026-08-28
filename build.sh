#!/bin/bash
set -e

echo "=== Starting Flutter Web Build for Vercel ==="

# Configure git safe directory globally
git config --global --add safe.directory "*" || true

# Clone Flutter SDK if not present
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

# Ensure newly cloned flutter repo is trusted by git
git config --global --add safe.directory "$PWD/flutter" || true
git config --global --add safe.directory "$PWD" || true

# Set environment variables
export FLUTTER_ROOT="$PWD/flutter"
export PATH="$PWD/flutter/bin:$PATH"

echo "Configuring Flutter..."
./flutter/bin/flutter config --no-analytics || true
./flutter/bin/flutter config --enable-web || true

echo "Checking Flutter environment..."
./flutter/bin/flutter --version

echo "Ensuring environment file exists..."
touch .env

echo "Fetching Flutter dependencies..."
./flutter/bin/flutter pub get

echo "Building Flutter Web Production Bundle..."
./flutter/bin/flutter build web --release --no-tree-shake-icons

echo "=== Build completed successfully! Output in build/web ==="
