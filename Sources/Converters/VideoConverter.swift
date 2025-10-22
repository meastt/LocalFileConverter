import Foundation

class VideoConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["mp4", "mov", "avi", "mkv", "webm", "gif"]

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
        case "mp4":
            arguments += [
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                "-b:a", "128k"
            ]
        case "webm":
            arguments += [
                "-c:v", "libvpx-vp9",
                "-crf", "30",
                "-b:v", "0",
                "-c:a", "libopus"
            ]
        case "gif":
            arguments += [
                "-vf", "fps=10,scale=480:-1:flags=lanczos",
                "-c:v", "gif"
            ]
        case "mov":
            arguments += [
                "-c:v", "libx264",
                "-preset", "medium",
                "-c:a", "aac"
            ]
        case "avi":
            arguments += [
                "-c:v", "mpeg4",
                "-q:v", "5",
                "-c:a", "mp3"
            ]
        case "mkv":
            arguments += [
                "-c:v", "libx264",
                "-c:a", "aac"
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
