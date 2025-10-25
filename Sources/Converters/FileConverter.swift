import Foundation

// Actor for thread-safe data collection during process execution
actor ProcessDataCollector {
    private var outputData = Data()
    private var errorData = Data()
    
    func appendOutput(_ data: Data) {
        outputData.append(data)
    }
    
    func appendError(_ data: Data) {
        errorData.append(data)
    }
    
    func getOutput() -> Data {
        return outputData
    }
    
    func getError() -> Data {
        return errorData
    }
}

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

        // Use actor for thread-safe data collection
        let dataCollector = ProcessDataCollector()

        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading

        // Set up background reading
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                Task {
                    await dataCollector.appendOutput(data)
                }
            }
        }

        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                Task {
                    await dataCollector.appendError(data)
                }
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()

                // Wait for process in background
                DispatchQueue.global(qos: .userInitiated).async {
                    process.waitUntilExit()

                    // Give a moment for final data to be read
                    Thread.sleep(forTimeInterval: 0.2)

                    // Stop reading
                    outputHandle.readabilityHandler = nil
                    errorHandle.readabilityHandler = nil

                    let status = process.terminationStatus

                    Task {
                        let finalOutput = await dataCollector.getOutput()
                        let finalError = await dataCollector.getError()

                        DispatchQueue.main.async {
                            progressHandler(1.0)

                            if status == 0 {
                                let output = String(data: finalOutput, encoding: .utf8) ?? ""
                                continuation.resume(returning: output)
                            } else {
                                let error = String(data: finalError, encoding: .utf8) ?? "Unknown error"
                                continuation.resume(throwing: ConversionError.conversionFailed(error))
                            }
                        }
                    }
                }
            } catch {
                continuation.resume(throwing: error)
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

    func generateOutputURL(for inputURL: URL, targetFormat: String, customOutputDirectory: URL? = nil) -> URL {
        let outputDirectory: URL

        if let customDir = customOutputDirectory {
            outputDirectory = customDir
        } else {
            outputDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("LocalFileConverter", isDirectory: true)
        }

        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let fileName = inputURL.deletingPathExtension().lastPathComponent
        let outputFileName = "\(fileName)_converted.\(targetFormat)"

        return outputDirectory.appendingPathComponent(outputFileName)
    }
}
