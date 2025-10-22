# Local File Converter for Mac

A privacy-focused, open-source macOS application that converts files locally on your machine - no sketchy online converters needed!

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.9-orange.svg)

## Why Local File Converter?

- **Privacy First**: All conversions happen locally on your Mac. Your files never leave your computer.
- **No Upload Limits**: Convert files of any size without worrying about file size restrictions.
- **Free & Open Source**: No subscriptions, no ads, no tracking.
- **Fast**: Powered by industry-standard tools like FFmpeg, ImageMagick, and Pandoc.
- **Batch Processing**: Convert multiple files at once.

## Supported Conversions

### Images
- **Formats**: JPEG, PNG, HEIC, TIFF, GIF, BMP, WebP, PDF
- **Powered by**: ImageMagick (or macOS built-in sips)

### Video
- **Formats**: MP4, MOV, AVI, MKV, WebM, GIF
- **Powered by**: FFmpeg

### Audio
- **Formats**: MP3, WAV, FLAC, AAC, OGG, M4A
- **Powered by**: FFmpeg

### Documents
- **Formats**: PDF, EPUB, MOBI, DOCX, TXT, HTML
- **Powered by**: Pandoc

### Archives
- **Formats**: ZIP, 7Z, TAR, TAR.GZ
- **Powered by**: Built-in Unix tools + 7z

## Installation

### Prerequisites

First, install the required conversion tools using Homebrew:

```bash
# Install Homebrew if you haven't already
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install conversion tools
brew install ffmpeg imagemagick pandoc p7zip
```

### Building the App

1. Clone this repository:
```bash
git clone https://github.com/yourusername/LocalFileConverter.git
cd LocalFileConverter
```

2. Open in Xcode:
```bash
open Package.swift
```

3. Build and run (⌘R) or create an archive for distribution (Product > Archive)

### Running from Command Line (Development)

```bash
swift run
```

## Usage

1. **Launch the app** - You'll see a drag-and-drop zone
2. **Drag files** into the window or click to browse
3. **Select output format** for each file from the dropdown
4. **Click "Convert All"** to start the conversion
5. **Access your files** by clicking "Show" when complete

All converted files are saved to:
```
~/Library/Caches/LocalFileConverter/
```

## Features

- ✅ Drag-and-drop interface
- ✅ Batch file conversion
- ✅ Real-time progress tracking
- ✅ Error handling with clear messages
- ✅ Native macOS design with SwiftUI
- ✅ Support for both Intel and Apple Silicon Macs

## Architecture

```
LocalFileConverter/
├── Sources/
│   ├── LocalFileConverterApp.swift    # App entry point
│   ├── ContentView.swift               # Main UI
│   ├── Models/
│   │   └── ConversionFile.swift        # Data models
│   ├── Managers/
│   │   └── ConversionManager.swift     # Conversion orchestration
│   └── Converters/
│       ├── FileConverter.swift         # Protocol & base class
│       ├── ImageConverter.swift        # Image conversions
│       ├── VideoConverter.swift        # Video conversions
│       ├── AudioConverter.swift        # Audio conversions
│       ├── DocumentConverter.swift     # Document conversions
│       └── ArchiveConverter.swift      # Archive conversions
└── Package.swift                       # Swift Package Manager config
```

## Conversion Details

### Image Conversions
- **Quality**: High quality presets (90-95% for JPEG/PNG)
- **Fallback**: Uses macOS built-in `sips` if ImageMagick not installed
- **Supports**: RAW formats via ImageMagick

### Video Conversions
- **MP4**: H.264 codec, AAC audio, medium preset
- **WebM**: VP9 codec, Opus audio
- **GIF**: Optimized for web (10fps, 480px width)
- **Quality**: Balanced settings for good size/quality ratio

### Audio Conversions
- **MP3**: 192kbps bitrate
- **FLAC**: Compression level 5 (balanced)
- **AAC/M4A**: 192kbps bitrate
- **WAV**: 16-bit PCM, 44.1kHz

### Document Conversions
- **PDF**: Uses XeLaTeX engine via Pandoc
- **EPUB/MOBI**: eBook formats for readers
- **DOCX**: Microsoft Word format

## Development Roadmap

### Phase 1 - MVP ✅
- [x] SwiftUI interface
- [x] Drag-and-drop support
- [x] Core conversion engines
- [x] Progress tracking
- [x] Error handling

### Phase 2 - Enhanced Features (Coming Soon)
- [ ] Conversion presets (Web-optimized, High-quality, etc.)
- [ ] Custom quality settings
- [ ] Output folder selection
- [ ] Conversion history
- [ ] Dark mode support

### Phase 3 - Distribution (Future)
- [ ] Code signing
- [ ] Notarization for macOS
- [ ] Mac App Store submission
- [ ] Automatic tool installation
- [ ] In-app updater

## Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Architecture**: Universal (Intel & Apple Silicon)

## Dependencies

All conversion tools are external command-line utilities:
- FFmpeg (video/audio)
- ImageMagick (images)
- Pandoc (documents)
- 7-Zip (archives)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Privacy Policy

**We don't collect any data.** Period.

All file conversions happen locally on your machine. No files, metadata, or usage statistics are ever transmitted to any server.

## Troubleshooting

### "FFmpeg not found"
Install via Homebrew: `brew install ffmpeg`

### "ImageMagick not found"
Install via Homebrew: `brew install imagemagick`
The app will fallback to macOS's built-in `sips` for basic image conversions.

### "Pandoc not found"
Install via Homebrew: `brew install pandoc`

### Conversion Failed
- Check that the input file isn't corrupted
- Ensure you have write permissions
- Try a different output format
- Check Console.app for detailed error logs

## Credits

Built with:
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Apple's modern UI framework
- [FFmpeg](https://ffmpeg.org/) - Multimedia processing
- [ImageMagick](https://imagemagick.org/) - Image processing
- [Pandoc](https://pandoc.org/) - Document conversion

## Support

If you find this app useful, consider:
- Starring the repository ⭐
- Sharing it with others
- Contributing code or documentation
- Reporting bugs or suggesting features

## Author

Created with ❤️ to provide a privacy-respecting alternative to online file converters.

---

**Note**: This is an MVP (Minimum Viable Product). Some features are still in development. Contributions and feedback are greatly appreciated!
