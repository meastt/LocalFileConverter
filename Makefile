.PHONY: build run clean install-deps test help

# Default target
help:
	@echo "Local File Converter - Available Commands"
	@echo "=========================================="
	@echo "make install-deps  - Install required conversion tools (FFmpeg, ImageMagick, etc.)"
	@echo "make build        - Build the application"
	@echo "make run          - Build and run the application"
	@echo "make clean        - Clean build artifacts"
	@echo "make release      - Build release version"
	@echo "make help         - Show this help message"

# Install dependencies using Homebrew
install-deps:
	@chmod +x install-dependencies.sh
	@./install-dependencies.sh

# Build the application in debug mode
build:
	@echo "Building Local File Converter..."
	@swift build

# Build and run the application
run:
	@echo "Building and running Local File Converter..."
	@swift run

# Build release version
release:
	@echo "Building release version..."
	@swift build -c release
	@echo "✅ Release build complete!"
	@echo "Binary located at: .build/release/LocalFileConverter"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@echo "✅ Clean complete!"

# Open in Xcode
xcode:
	@echo "Opening in Xcode..."
	@open Package.swift

# Check tool availability
check-tools:
	@echo "Checking conversion tools..."
	@command -v ffmpeg >/dev/null 2>&1 && echo "✅ FFmpeg installed" || echo "❌ FFmpeg not found"
	@command -v magick >/dev/null 2>&1 && echo "✅ ImageMagick installed" || echo "❌ ImageMagick not found"
	@command -v pandoc >/dev/null 2>&1 && echo "✅ Pandoc installed" || echo "❌ Pandoc not found"
	@command -v 7z >/dev/null 2>&1 && echo "✅ 7-Zip installed" || echo "❌ 7-Zip not found"
	@command -v yt-dlp >/dev/null 2>&1 && echo "✅ yt-dlp installed" || echo "❌ yt-dlp not found"
