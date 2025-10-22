import Foundation

class ImageConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["jpg", "jpeg", "png", "heic", "tiff", "gif", "bmp", "webp", "pdf"]

    func convert(
        inputURL: URL,
        targetFormat: String,
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
                progressHandler: progressHandler
            )
        } else {
            return try await convertWithSips(
                inputURL: inputURL,
                targetFormat: targetFormat,
                progressHandler: progressHandler
            )
        }
    }

    private func convertWithImageMagick(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat)

        var arguments = [
            "convert",
            inputURL.path
        ]

        // Add quality settings based on format
        switch targetFormat.lowercased() {
        case "jpg", "jpeg":
            arguments += ["-quality", "90"]
        case "png":
            arguments += ["-quality", "95"]
        case "webp":
            arguments += ["-quality", "85"]
        default:
            break
        }

        arguments.append(outputURL.path)

        _ = try await runCommand("magick", arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }

    private func convertWithSips(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat)

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

        let arguments = [
            "-s", "format", sipsFormat,
            inputURL.path,
            "--out", outputURL.path
        ]

        _ = try await runCommand("/usr/bin/sips", arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
}
