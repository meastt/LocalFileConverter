import Foundation

class DocumentConverter: CommandLineConverter, FileConverter {
    private let supportedFormats = ["pdf", "epub", "mobi", "docx", "txt", "html"]

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

        // Try Pandoc first, fallback to other methods
        if checkToolAvailability("pandoc") {
            return try await convertWithPandoc(
                inputURL: inputURL,
                targetFormat: targetFormat,
                progressHandler: progressHandler
            )
        } else if targetFormat == "pdf" && checkToolAvailability("cupsfilter") {
            return try await convertToPDFWithCups(
                inputURL: inputURL,
                progressHandler: progressHandler
            )
        } else {
            throw ConversionError.toolNotFound("Pandoc or alternative converter")
        }
    }

    private func convertWithPandoc(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: targetFormat, customOutputDirectory: UserSettings.shared.outputDirectory)

        var arguments = [
            inputURL.path,
            "-o", outputURL.path
        ]

        // Add format-specific settings
        switch targetFormat.lowercased() {
        case "pdf":
            arguments += [
                "--pdf-engine=xelatex"
            ]
        case "epub":
            arguments += [
                "--epub-cover-image=/dev/null"
            ]
        case "docx":
            arguments += [
                "--reference-doc=/dev/null"
            ]
        default:
            break
        }

        let pandocPath = findExecutablePath("pandoc") ?? "/opt/homebrew/bin/pandoc"
        _ = try await runCommand(pandocPath, arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }

    private func convertToPDFWithCups(
        inputURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let outputURL = generateOutputURL(for: inputURL, targetFormat: "pdf", customOutputDirectory: UserSettings.shared.outputDirectory)

        let arguments = [
            inputURL.path,
            outputURL.path
        ]

        let cupsfilterPath = findExecutablePath("cupsfilter") ?? "/usr/bin/cupsfilter"
        _ = try await runCommand(cupsfilterPath, arguments: arguments, progressHandler: progressHandler)

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.conversionFailed("Output file not created")
        }

        return outputURL
    }
}
