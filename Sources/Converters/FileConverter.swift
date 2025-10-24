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
        workingDirectory: URL? = nil,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Set working directory if specified
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try process.run()

                    // Simulate progress updates using Task-based timing (no memory leaks)
                    let progressTask = Task {
                        var progress: Double = 0.0
                        while progress < 0.9 && process.isRunning {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            progress += 0.05
                            await MainActor.run {
                                progressHandler(progress)
                            }
                        }
                    }

                    process.waitUntilExit()
                    progressTask.cancel()

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus == 0 {
                        await MainActor.run {
                            progressHandler(1.0)
                        }
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
    
    func findExecutablePath(_ toolName: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return output
            }
        } catch {
            // Ignore errors
        }
        
        return nil
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
