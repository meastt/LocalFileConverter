import Foundation

protocol FileConverter {
    func convert(
        inputURL: URL,
        targetFormat: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL
}

enum ConversionError: LocalizedError {
    case unsupportedFormat
    case toolNotFound(String)
    case conversionFailed(String)
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported file format"
        case .toolNotFound(let tool):
            return "\(tool) not found. Please install it."
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        case .fileNotFound:
            return "Input file not found"
        }
    }
}

class CommandLineConverter {
    func runCommand(
        _ command: String,
        arguments: [String],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try process.run()

                    // Simulate progress updates
                    var progress: Double = 0.0
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        progress += 0.05
                        if progress <= 0.9 {
                            progressHandler(progress)
                        }
                        if progress >= 1.0 {
                            timer.invalidate()
                        }
                    }

                    process.waitUntilExit()
                    timer.invalidate()

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus == 0 {
                        progressHandler(1.0)
                        let output = String(data: outputData, encoding: .utf8) ?? ""
                        continuation.resume(returning: output)
                    } else {
                        let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: ConversionError.conversionFailed(error))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func checkToolAvailability(_ toolName: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    func generateOutputURL(for inputURL: URL, targetFormat: String) -> URL {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalFileConverter", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let fileName = inputURL.deletingPathExtension().lastPathComponent
        let outputFileName = "\(fileName)_converted.\(targetFormat)"

        return outputDirectory.appendingPathComponent(outputFileName)
    }
}
