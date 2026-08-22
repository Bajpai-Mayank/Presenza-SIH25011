#!/bin/bash
set -e

echo "=== Starting Flutter Web Build for Vercel ==="

# Configure git safe directory
git config --global --add safe.directory "*" || true

# Check if flutter is already installed, if not, download it
if ! command -v flutter &> /dev/null; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
  export PATH="`pwd`/_flutter/bin:$PATH"
fi

echo "Configuring Flutter..."
flutter config --no-analytics || true
flutter config --enable-web || true

echo "Flutter version:"
flutter --version

echo "Fetching dependencies..."
flutter pub get

echo "Building Flutter Web Release..."
flutter build web --release --no-tree-shake-icons

echo "=== Build completed successfully! Output in build/web ==="
