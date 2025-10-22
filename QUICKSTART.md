# Quick Start Guide

Get up and running with Local File Converter in 5 minutes!

## Step 1: Install Dependencies

Run the automated installation script:

```bash
chmod +x install-dependencies.sh
./install-dependencies.sh
```

This will install:
- FFmpeg (video/audio conversion)
- ImageMagick (image conversion)
- Pandoc (document conversion)
- 7-Zip (archive conversion)

Or use the Makefile:

```bash
make install-deps
```

## Step 2: Build the App

### Option A: Using Xcode (Recommended)

```bash
open Package.swift
```

Then press `⌘R` to build and run.

### Option B: Command Line

```bash
make run
```

Or directly with Swift:

```bash
swift run
```

## Step 3: Use the App

1. **Drag files** into the window
2. **Select output format** from dropdown
3. **Click "Convert All"**
4. **Click "Show"** to view converted files

## Common Use Cases

### Convert Image to Different Format
- Drag a HEIC photo
- Select "jpg" from dropdown
- Click "Convert All"
- Get a JPEG version!

### Make a GIF from Video
- Drag an MP4 video
- Select "gif" from dropdown
- Get an animated GIF!

### Extract and Recompress Archives
- Drag a RAR file
- Select "zip" from dropdown
- Get a ZIP version!

### Convert Audio Files
- Drag a FLAC file
- Select "mp3" from dropdown
- Get an MP3 version!

## Troubleshooting

### Build Errors

**"Cannot find 'NSColor'"**
- Make sure you're building for macOS target
- Check Platform is set to macOS in Xcode

**"Module not found"**
- Clean build folder: `make clean`
- Rebuild: `make build`

### Runtime Errors

**"FFmpeg not found"**
```bash
brew install ffmpeg
```

**"ImageMagick not found"**
```bash
brew install imagemagick
```

**"Conversion failed"**
- Check the input file isn't corrupted
- Try a different output format
- Check Console.app for detailed logs

## File Locations

**Converted files are saved to:**
```
~/Library/Caches/LocalFileConverter/
```

**To change output location:**
Currently files are saved to temp directory. Custom output location coming in Phase 2!

## Keyboard Shortcuts

- `⌘W` - Close window
- `⌘Q` - Quit app
- Drag & Drop - Add files

## Supported Conversions

### Images
JPEG ↔ PNG ↔ HEIC ↔ TIFF ↔ GIF ↔ BMP ↔ WebP ↔ PDF

### Video
MP4 ↔ MOV ↔ AVI ↔ MKV ↔ WebM → GIF

### Audio
MP3 ↔ WAV ↔ FLAC ↔ AAC ↔ OGG ↔ M4A

### Documents
PDF ↔ EPUB ↔ MOBI ↔ DOCX ↔ TXT ↔ HTML

### Archives
ZIP ↔ 7Z ↔ TAR ↔ TAR.GZ

## Tips

✨ **Batch Processing**: Drag multiple files at once to convert them all

✨ **Quality**: Image and video conversions use high-quality presets by default

✨ **Privacy**: All conversions happen locally - nothing is uploaded anywhere

✨ **Speed**: FFmpeg and ImageMagick are incredibly fast

## Next Steps

- Read the full [README.md](README.md)
- Check out [CONTRIBUTING.md](CONTRIBUTING.md) to add features
- Report bugs or request features via GitHub Issues

## Need Help?

- Check the [README](README.md) for detailed information
- Look at existing [GitHub Issues](https://github.com/yourusername/LocalFileConverter/issues)
- Create a new issue if your problem isn't listed

---

Happy converting! 🎉
