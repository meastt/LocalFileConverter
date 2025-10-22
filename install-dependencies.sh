#!/bin/bash

# Local File Converter - Dependency Installation Script
# This script installs all required conversion tools

set -e

echo "=================================="
echo "Local File Converter Setup"
echo "=================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed."
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed successfully!"
else
    echo "✅ Homebrew is already installed"
fi

echo ""
echo "Installing conversion tools..."
echo ""

# Update Homebrew
echo "📦 Updating Homebrew..."
brew update

# Install FFmpeg (for video/audio)
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg is already installed"
else
    echo "📦 Installing FFmpeg (video/audio conversion)..."
    brew install ffmpeg
    echo "✅ FFmpeg installed!"
fi

# Install ImageMagick (for images)
if command -v magick &> /dev/null; then
    echo "✅ ImageMagick is already installed"
else
    echo "📦 Installing ImageMagick (image conversion)..."
    brew install imagemagick
    echo "✅ ImageMagick installed!"
fi

# Install Pandoc (for documents)
if command -v pandoc &> /dev/null; then
    echo "✅ Pandoc is already installed"
else
    echo "📦 Installing Pandoc (document conversion)..."
    brew install pandoc
    echo "✅ Pandoc installed!"
fi

# Install p7zip (for 7z archives)
if command -v 7z &> /dev/null; then
    echo "✅ 7-Zip is already installed"
else
    echo "📦 Installing 7-Zip (archive conversion)..."
    brew install p7zip
    echo "✅ 7-Zip installed!"
fi

echo ""
echo "=================================="
echo "✅ All dependencies installed!"
echo "=================================="
echo ""
echo "Installed tools:"
echo "  - FFmpeg: $(ffmpeg -version | head -n1)"
echo "  - ImageMagick: $(magick --version | head -n1)"
echo "  - Pandoc: $(pandoc --version | head -n1)"
echo "  - 7-Zip: $(7z | head -n2 | tail -n1)"
echo ""
echo "You can now build and run Local File Converter!"
echo ""
echo "Next steps:"
echo "  1. Open Package.swift in Xcode"
echo "  2. Build and run the app (⌘R)"
echo ""
echo "Or run from command line:"
echo "  swift run"
echo ""
