import Foundation

// MARK: - Image Processing Options
struct ImageProcessingOptions {
    let resizeMode: ResizeMode?
    let compressionQuality: Int?
    let cropRect: CropRect?
    let rotation: Rotation?
    let removeBackground: Bool
    let preset: ProcessingPreset?
    
    enum ResizeMode {
        case dimensions(width: Int, height: Int, maintainAspectRatio: Bool)
        case percentage(Int) // 50 = 50%
        case maxDimension(Int) // Resize so largest dimension is this value
    }
    
    struct CropRect {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }
    
    enum Rotation {
        case degrees90
        case degrees180
        case degrees270
    }
    
    enum ProcessingPreset {
        case webOptimized
        case highQuality
        case smallFileSize
        case socialMedia
        case print
    }
}

class ImageConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["jpg", "jpeg", "png", "heic", "tiff", "gif", "bmp", "webp", "pdf"]

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
        options: ImageProcessingOptions?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        guard supportedFormats.contains(targetFormat.lowercased()) else {
            throw ConversionError.unsupportedFormat
        }

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.fileNotFound
        }

        // Try ImageMagick first, fallback to sips (macOS built-in)
        if checkToolAvailability("magick") {
            return try await convertWithImageMagick(
                inputURL: inputURL,
                targetFormat: targetFormat,
                options: options,
                progressHandler: progressHandler
            )
        } else {
            return try await convertWithSips(
                inputURL: inputURL,
                targetFormat: targetFormat,
                options: options,
                progressHandler: progressHandler
            )
        }
    }

    private func convertWithImageMagick(
        inputURL: URL,
        targetFormat: String,
        options: ImageProcessingOptions?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat, customOutputDirectory: UserSettings.shared.outputDirectory)

        var arguments = [
            "convert",
            inputURL.path
        ]

        // Apply processing options
        if let options = options {
            arguments += buildImageMagickArguments(for: options, targetFormat: targetFormat)
        } else {
            // Default quality settings based on format
            arguments += getDefaultQualitySettings(for: targetFormat)
        }

        arguments.append(outputURL.path)

        let magickPath = findExecutablePath("magick") ?? "/opt/homebrew/bin/magick"
        _ = try await runCommand(magickPath, arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
    
    private func buildImageMagickArguments(for options: ImageProcessingOptions, targetFormat: String) -> [String] {
        var arguments: [String] = []
        
        // Apply preset if specified
        if let preset = options.preset {
            arguments += getPresetArguments(for: preset, targetFormat: targetFormat)
        }
        
        // Resize operations
        if let resizeMode = options.resizeMode {
            arguments += getResizeArguments(for: resizeMode)
        }
        
        // Crop operation
        if let cropRect = options.cropRect {
            arguments += ["-crop", "\(cropRect.width)x\(cropRect.height)+\(cropRect.x)+\(cropRect.y)"]
        }
        
        // Rotation
        if let rotation = options.rotation {
            arguments += getRotationArguments(for: rotation)
        }
        
        // Background removal
        if options.removeBackground {
            arguments += getBackgroundRemovalArguments()
        }
        
        // Custom quality if specified
        if let quality = options.compressionQuality {
            arguments += ["-quality", "\(quality)"]
        } else if options.preset == nil {
            // Use default quality if no preset and no custom quality
            arguments += getDefaultQualitySettings(for: targetFormat)
        }
        
        return arguments
    }
    
    private func getPresetArguments(for preset: ImageProcessingOptions.ProcessingPreset, targetFormat: String) -> [String] {
        switch preset {
        case .webOptimized:
            return [
                "-resize", "1920x1920>", // Max 1920px, maintain aspect ratio
                "-quality", "85",
                "-strip" // Remove metadata
            ]
        case .highQuality:
            return [
                "-quality", "95",
                "-sharpen", "0x1" // Slight sharpening
            ]
        case .smallFileSize:
            return [
                "-resize", "800x800>", // Max 800px
                "-quality", "75",
                "-strip"
            ]
        case .socialMedia:
            return [
                "-resize", "1080x1080^", // Instagram square format
                "-gravity", "center",
                "-crop", "1080x1080+0+0",
                "-quality", "90",
                "-strip"
            ]
        case .print:
            return [
                "-density", "300", // 300 DPI for print
                "-quality", "100",
                "-colorspace", "CMYK"
            ]
        }
    }
    
    private func getResizeArguments(for resizeMode: ImageProcessingOptions.ResizeMode) -> [String] {
        switch resizeMode {
        case .dimensions(let width, let height, let maintainAspectRatio):
            if maintainAspectRatio {
                return ["-resize", "\(width)x\(height)>"] // Maintain aspect ratio
            } else {
                return ["-resize", "\(width)x\(height)!"] // Force exact dimensions
            }
        case .percentage(let percent):
            return ["-resize", "\(percent)%"]
        case .maxDimension(let maxDim):
            return ["-resize", "\(maxDim)x\(maxDim)>"] // Max dimension, maintain aspect ratio
        }
    }
    
    private func getRotationArguments(for rotation: ImageProcessingOptions.Rotation) -> [String] {
        switch rotation {
        case .degrees90:
            return ["-rotate", "90"]
        case .degrees180:
            return ["-rotate", "180"]
        case .degrees270:
            return ["-rotate", "270"]
        }
    }
    
    private func getBackgroundRemovalArguments() -> [String] {
        return [
            "-fuzz", "10%", // Color tolerance
            "-transparent", "white", // Remove white background
            "-background", "transparent"
        ]
    }
    
    private func getDefaultQualitySettings(for targetFormat: String) -> [String] {
        switch targetFormat.lowercased() {
        case "jpg", "jpeg":
            return ["-quality", "90"]
        case "png":
            return ["-quality", "95"]
        case "webp":
            return ["-quality", "85"]
        default:
            return []
        }
    }

    private func convertWithSips(
        inputURL: URL,
        targetFormat: String,
        options: ImageProcessingOptions?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat, customOutputDirectory: UserSettings.shared.outputDirectory)

        let sipsFormat: String
        switch targetFormat.lowercased() {
        case "jpg", "jpeg": sipsFormat = "jpeg"
        case "png": sipsFormat = "png"
        case "tiff": sipsFormat = "tiff"
        case "gif": sipsFormat = "gif"
        case "bmp": sipsFormat = "bmp"
        default:
            throw ConversionError.unsupportedFormat
        }

        var arguments = [
            "-s", "format", sipsFormat,
            inputURL.path,
            "--out", outputURL.path
        ]
        
        // Apply basic processing options (sips has limited capabilities)
        if let options = options {
            if let resizeMode = options.resizeMode {
                switch resizeMode {
                case .dimensions(let width, let height, _):
                    arguments += ["-z", "\(width)", "\(height)"]
                case .percentage(let percent):
                    arguments += ["-Z", "\(percent)"]
                case .maxDimension(let maxDim):
                    arguments += ["-Z", "\(maxDim)"]
                }
            }
            
            if let rotation = options.rotation {
                switch rotation {
                case .degrees90:
                    arguments += ["-r", "90"]
                case .degrees180:
                    arguments += ["-r", "180"]
                case .degrees270:
                    arguments += ["-r", "270"]
                }
            }
        }

        _ = try await runCommand("/usr/bin/sips", arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
}
