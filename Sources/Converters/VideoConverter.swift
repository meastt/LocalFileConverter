import Foundation

// MARK: - Video Processing Options
struct VideoProcessingOptions {
    let resizeMode: VideoResizeMode?
    let compressionLevel: CompressionLevel?
    let preset: VideoPreset?
    let trimStart: Double? // seconds
    let trimEnd: Double? // seconds
    
    enum VideoResizeMode {
        case dimensions(width: Int, height: Int)
        case scale(Int) // percentage
        case maxDimension(Int) // max width or height
    }
    
    enum CompressionLevel {
        case low // Larger file, better quality
        case medium // Balanced
        case high // Smaller file, lower quality
        case custom(bitrate: String) // Custom bitrate like "2M"
    }
    
    enum VideoPreset {
        case webOptimized // MP4, H.264, optimized for web
        case highQuality // High bitrate, best quality
        case smallFileSize // Lower bitrate, smaller file
        case socialMedia // Optimized for Instagram/TikTok
        case gifOptimized // Optimized for GIF conversion
    }
}

class VideoConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["mp4", "mov", "avi", "mkv", "webm", "gif"]

    func convert(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        return try await convert(
            inputURL: inputURL,
            targetFormat: targetFormat,
            options: nil,
            progressHandler: progressHandler
        )
    }
    
    func convert(
        inputURL: URL,
        targetFormat: String,
        options: VideoProcessingOptions?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        guard supportedFormats.contains(targetFormat.lowercased()) else {
            throw ConversionError.unsupportedFormat
        }

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        guard checkToolAvailability("ffmpeg") else {
            throw ConversionError.toolNotFound("FFmpeg")
        }

        return try await convertWithFFmpeg(
            inputURL: inputURL,
            targetFormat: targetFormat,
            options: options,
            progressHandler: progressHandler
        )
    }

    private func convertWithFFmpeg(
        inputURL: URL,
        targetFormat: String,
        options: VideoProcessingOptions?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat)

        var arguments = [
            "-i", inputURL.path,
            "-y" // Overwrite output file
        ]

        // Apply processing options
        if let options = options {
            arguments += buildFFmpegArguments(for: options, targetFormat: targetFormat)
        } else {
            // Default format-specific settings
            arguments += getDefaultFormatSettings(for: targetFormat)
        }

        arguments.append(outputURL.path)

        let ffmpegPath = findExecutablePath("ffmpeg") ?? "/opt/homebrew/bin/ffmpeg"
        _ = try await runCommand(ffmpegPath, arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
    
    private func buildFFmpegArguments(for options: VideoProcessingOptions, targetFormat: String) -> [String] {
        var arguments: [String] = []
        
        // Apply preset if specified
        if let preset = options.preset {
            arguments += getPresetArguments(for: preset, targetFormat: targetFormat)
        }
        
        // Trim video if specified
        if let start = options.trimStart {
            arguments += ["-ss", "\(start)"]
        }
        if let end = options.trimEnd {
            arguments += ["-to", "\(end)"]
        }
        
        // Resize operations
        if let resizeMode = options.resizeMode {
            arguments += getResizeArguments(for: resizeMode)
        }
        
        // Compression level
        if let compression = options.compressionLevel {
            arguments += getCompressionArguments(for: compression)
        }
        
        // If no preset specified, use default format settings
        if options.preset == nil {
            arguments += getDefaultFormatSettings(for: targetFormat)
        }
        
        return arguments
    }
    
    private func getPresetArguments(for preset: VideoProcessingOptions.VideoPreset, targetFormat: String) -> [String] {
        switch preset {
        case .webOptimized:
            return [
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                "-b:a", "128k",
                "-movflags", "+faststart" // Web optimization
            ]
        case .highQuality:
            return [
                "-c:v", "libx264",
                "-preset", "slow",
                "-crf", "18",
                "-c:a", "aac",
                "-b:a", "256k"
            ]
        case .smallFileSize:
            return [
                "-c:v", "libx264",
                "-preset", "fast",
                "-crf", "28",
                "-c:a", "aac",
                "-b:a", "96k"
            ]
        case .socialMedia:
            return [
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                "-b:a", "128k",
                "-vf", "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2:black"
            ]
        case .gifOptimized:
            return [
                "-vf", "fps=10,scale=480:-1:flags=lanczos",
                "-c:v", "gif"
            ]
        }
    }
    
    private func getResizeArguments(for resizeMode: VideoProcessingOptions.VideoResizeMode) -> [String] {
        switch resizeMode {
        case .dimensions(let width, let height):
            return ["-vf", "scale=\(width):\(height)"]
        case .scale(let percent):
            return ["-vf", "scale=iw*\(percent)/100:ih*\(percent)/100"]
        case .maxDimension(let maxDim):
            return ["-vf", "scale='min(\(maxDim),iw)':'min(\(maxDim),ih)':force_original_aspect_ratio=decrease"]
        }
    }
    
    private func getCompressionArguments(for compression: VideoProcessingOptions.CompressionLevel) -> [String] {
        switch compression {
        case .low:
            return ["-crf", "18", "-preset", "slow"]
        case .medium:
            return ["-crf", "23", "-preset", "medium"]
        case .high:
            return ["-crf", "28", "-preset", "fast"]
        case .custom(let bitrate):
            return ["-b:v", bitrate]
        }
    }
    
    private func getDefaultFormatSettings(for targetFormat: String) -> [String] {
        switch targetFormat.lowercased() {
        case "mp4":
            return [
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                "-b:a", "128k"
            ]
        case "webm":
            return [
                "-c:v", "libvpx-vp9",
                "-crf", "30",
                "-b:v", "0",
                "-c:a", "libopus"
            ]
        case "gif":
            return [
                "-vf", "fps=10,scale=480:-1:flags=lanczos",
                "-c:v", "gif"
            ]
        case "mov":
            return [
                "-c:v", "libx264",
                "-preset", "medium",
                "-c:a", "aac"
            ]
        case "avi":
            return [
                "-c:v", "mpeg4",
                "-q:v", "5",
                "-c:a", "mp3"
            ]
        case "mkv":
            return [
                "-c:v", "libx264",
                "-c:a", "aac"
            ]
        default:
            return []
        }
    }
}
