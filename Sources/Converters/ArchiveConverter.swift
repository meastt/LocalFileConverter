import Foundation

class ArchiveConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["zip", "7z", "tar", "tar.gz"]

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

        // First, extract the archive
        let extractedDir = try await extractArchive(inputURL: inputURL, progressHandler: progressHandler)

        // Then, create new archive in target format
        return try await createArchive(
            sourceDir: extractedDir,
            targetFormat: targetFormat,
            baseName: inputURL.deletingPathExtension().lastPathComponent,
            progressHandler: progressHandler
        )
    }

    private func extractArchive(
        inputURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalFileConverter_Extract_\(UUID().uuidString)", isDirectory: true)

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let ext = inputURL.pathExtension.lowercased()

        switch ext {
        case "zip":
            _ = try await runCommand(
                "/usr/bin/unzip",
                arguments: ["-q", inputURL.path, "-d", tempDir.path],
                progressHandler: { progress in progressHandler(progress * 0.5) }
            )
        case "7z":
            guard checkToolAvailability("7z") else {
                throw ConversionError.toolNotFound("7z")
            }
            let sevenZipPath = findExecutablePath("7z") ?? "/opt/homebrew/bin/7z"
            _ = try await runCommand(
                sevenZipPath,
                arguments: ["x", inputURL.path, "-o\(tempDir.path)", "-y"],
                progressHandler: { progress in progressHandler(progress * 0.5) }
            )
        case "tar", "gz", "tgz":
            _ = try await runCommand(
                "/usr/bin/tar",
                arguments: ["-xzf", inputURL.path, "-C", tempDir.path],
                progressHandler: { progress in progressHandler(progress * 0.5) }
            )
        case "rar":
            guard checkToolAvailability("unrar") else {
                throw ConversionError.toolNotFound("unrar")
            }
            let unrarPath = findExecutablePath("unrar") ?? "/opt/homebrew/bin/unrar"
            _ = try await runCommand(
                unrarPath,
                arguments: ["x", inputURL.path, tempDir.path],
                progressHandler: { progress in progressHandler(progress * 0.5) }
            )
        default:
            throw ConversionError.unsupportedFormat
        }

        return tempDir
    }

    private func createArchive(
        sourceDir: URL,
        targetFormat: String,
        baseName: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: sourceDir, targetFormat: targetFormat, customOutputDirectory: UserSettings.shared.outputDirectory)
            .deletingLastPathComponent()
            .appendingPathComponent("\(baseName)_converted.\(targetFormat)")

        switch targetFormat.lowercased() {
        case "zip":
            _ = try await runCommand(
                "/usr/bin/zip",
                arguments: ["-r", "-q", outputURL.path, "."],
                progressHandler: { progress in progressHandler(0.5 + progress * 0.5) }
            )
        case "7z":
            guard checkToolAvailability("7z") else {
                throw ConversionError.toolNotFound("7z")
            }
            let sevenZipPath = findExecutablePath("7z") ?? "/opt/homebrew/bin/7z"
            _ = try await runCommand(
                sevenZipPath,
                arguments: ["a", outputURL.path, "\(sourceDir.path)/*"],
                progressHandler: { progress in progressHandler(0.5 + progress * 0.5) }
            )
        case "tar":
            _ = try await runCommand(
                "/usr/bin/tar",
                arguments: ["-cf", outputURL.path, "-C", sourceDir.path, "."],
                progressHandler: { progress in progressHandler(0.5 + progress * 0.5) }
            )
        case "tar.gz":
            _ = try await runCommand(
                "/usr/bin/tar",
                arguments: ["-czf", outputURL.path, "-C", sourceDir.path, "."],
                progressHandler: { progress in progressHandler(0.5 + progress * 0.5) }
            )
        default:
            throw ConversionError.unsupportedFormat
        }

        // Clean up extracted directory
        try? FileManager.default.removeItem(at: sourceDir)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
}
