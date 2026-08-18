#!/bin/bash
set -e

echo "=== Starting Flutter Web Build for Vercel ==="

# Check if flutter is already installed, if not, download it
if ! command -v flutter &> /dev/null; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
  export PATH="$PATH:`pwd`/_flutter/bin"
fi

echo "Flutter version:"
flutter --version

echo "Fetching dependencies..."
flutter pub get

echo "Building Flutter Web Release..."
flutter build web --release

echo "=== Build completed successfully! Output in build/web ==="
