import Foundation

class AudioConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["mp3", "wav", "flac", "aac", "ogg", "m4a"]

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

        guard checkToolAvailability("ffmpeg") else {
            throw ConversionError.toolNotFound("FFmpeg")
        }

        return try await convertWithFFmpeg(
            inputURL: inputURL,
            targetFormat: targetFormat,
            progressHandler: progressHandler
        )
    }

    private func convertWithFFmpeg(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat)

        var arguments = [
            "-i", inputURL.path,
            "-y" // Overwrite output file
        ]

        // Add format-specific settings
        switch targetFormat.lowercased() {
        case "mp3":
            arguments += [
                "-c:a", "libmp3lame",
                "-b:a", "192k"
            ]
        case "wav":
            arguments += [
                "-c:a", "pcm_s16le",
                "-ar", "44100"
            ]
        case "flac":
            arguments += [
                "-c:a", "flac",
                "-compression_level", "5"
            ]
        case "aac", "m4a":
            arguments += [
                "-c:a", "aac",
                "-b:a", "192k"
            ]
        case "ogg":
            arguments += [
                "-c:a", "libvorbis",
                "-q:a", "5"
            ]
        default:
            break
        }

        arguments.append(outputURL.path)

        _ = try await runCommand("ffmpeg", arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
}
