import Foundation
import Combine

@MainActor
class ConversionManager: ObservableObject {
    @Published var files: [ConversionFile] = []
    @Published var isConverting = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private var converters: [FileType: any FileConverter] = [:]
    private let videoDownloader = VideoDownloader()

    // Maximum file size: 5GB
    private let maxFileSize: Int64 = 5_000_000_000

    init() {
        setupConverters()
    }

    private func setupConverters() {
        converters[.image] = ImageConverter()
        converters[.video] = VideoConverter()
        converters[.audio] = AudioConverter()
        converters[.document] = DocumentConverter()
        converters[.archive] = ArchiveConverter()
    }

    func addFile(url: URL) {
        let fileType = FileType.detect(from: url)
        guard fileType != .unknown else {
            alertTitle = "Unsupported File Type"
            alertMessage = "The file '\(url.lastPathComponent)' is not a supported format."
            showingAlert = true
            return
        }

        // Check file size (skip for remote URLs)
        if url.scheme != "http" && url.scheme != "https" {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? Int64 {
                if size > maxFileSize {
                    let sizeInGB = Double(size) / 1_000_000_000.0
                    alertTitle = "File Too Large"
                    alertMessage = "The file '\(url.lastPathComponent)' is \(String(format: "%.1f", sizeInGB))GB. Files larger than 5GB are not supported to prevent system issues."
                    showingAlert = true
                    return
                }
            }
        }

        var file = ConversionFile(url: url, fileType: fileType)
        file.targetFormat = file.detectedFormats.first
        files.append(file)
    }
    
    func addVideoURL(_ urlString: String) async {
        guard VideoDownloader.isValidVideoURL(urlString) else {
            return
        }

        do {
            let videoInfo = try await videoDownloader.getVideoInfo(from: urlString)

            var tempFile = ConversionFile(
                url: URL(string: urlString)!,
                fileType: .video,
                metadata: ["title": videoInfo.title, "duration": videoInfo.durationFormatted]
            )
            tempFile.targetFormat = "mp4"
            files.append(tempFile)
        } catch {
            print("Failed to get video info: \(error.localizedDescription)")
        }
    }

    func removeFile(id: UUID) {
        files.removeAll { $0.id == id }
    }

    func clearAll() {
        files.removeAll()
    }

    func moveFiles(from source: IndexSet, to destination: Int) {
        files.move(fromOffsets: source, toOffset: destination)
    }

    func setTargetFormat(for fileId: UUID, format: String) {
        if let index = files.firstIndex(where: { $0.id == fileId }) {
            files[index].targetFormat = format
        }
    }
    
    func setImageProcessingOptions(for fileId: UUID, options: ImageProcessingOptions) {
        if let index = files.firstIndex(where: { $0.id == fileId }) {
            files[index].imageProcessingOptions = options
        }
    }
    
    func setVideoProcessingOptions(for fileId: UUID, options: VideoProcessingOptions) {
        if let index = files.firstIndex(where: { $0.id == fileId }) {
            files[index].videoProcessingOptions = options
        }
    }

    func retryFile(id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        // Reset status to nil and convert
        files[index].status = nil
        Task {
            await convertFile(at: index)
        }
    }

    func convertAll() {
        Task {
            isConverting = true
            defer { isConverting = false }

            // Collect indices of files that need conversion
            let indicesToConvert = files.indices.filter { i in
                files[i].status == nil || files[i].status?.isFailed == true
            }

            // Convert files in parallel using TaskGroup
            await withTaskGroup(of: Void.self) { group in
                for i in indicesToConvert {
                    group.addTask {
                        await self.convertFile(at: i)
                    }
                }
            }
        }
    }

    private func convertFile(at index: Int) async {
        guard index < files.count else { return }

        let file = files[index]
        guard let targetFormat = file.targetFormat else { return }

        files[index].status = .converting(progress: 0.0)

        // Track downloaded file for cleanup
        var downloadedFileToCleanup: URL?

        // Handle video URLs (download first)
        if file.url.scheme == "http" || file.url.scheme == "https" {
            do {
                let downloadedURL = try await videoDownloader.downloadVideo(
                    from: file.url.absoluteString,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            if let self = self, index < self.files.count {
                                self.files[index].status = .converting(progress: progress)
                            }
                        }
                    }
                )

                // Check if already in target format
                let downloadedFormat = downloadedURL.pathExtension.lowercased()
                if downloadedFormat == targetFormat.lowercased() {
                    // Move to user's output directory if set
                    let finalURL: URL
                    if let outputDir = UserSettings.shared.outputDirectory {
                        finalURL = outputDir.appendingPathComponent(downloadedURL.lastPathComponent)
                        try? FileManager.default.copyItem(at: downloadedURL, to: finalURL)
                    } else {
                        finalURL = downloadedURL
                    }

                    files[index].status = .completed
                    files[index].url = finalURL
                    return
                }

                files[index].url = downloadedURL
                downloadedFileToCleanup = downloadedURL
            } catch {
                files[index].status = .failed(error: error.localizedDescription)
                return
            }
        }

        guard let converter = converters[file.fileType] else {
            files[index].status = .failed(error: "No converter available")
            return
        }

        do {
            // Update progress periodically
            files[index].status = .converting(progress: 0.3)

            let outputURL: URL
            
            // Use enhanced converters with processing options
            if let imageConverter = converter as? ImageConverter,
               let imageOptions = file.imageProcessingOptions {
                outputURL = try await imageConverter.convert(
                    inputURL: file.url,
                    targetFormat: targetFormat,
                    options: imageOptions,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            if let self = self, index < self.files.count {
                                self.files[index].status = .converting(progress: 0.5 + progress * 0.5)
                            }
                        }
                    }
                )
            } else if let videoConverter = converter as? VideoConverter,
                      let videoOptions = file.videoProcessingOptions {
                outputURL = try await videoConverter.convert(
                    inputURL: file.url,
                    targetFormat: targetFormat,
                    options: videoOptions,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            if let self = self, index < self.files.count {
                                self.files[index].status = .converting(progress: 0.5 + progress * 0.5)
                            }
                        }
                    }
                )
            } else {
                // Standard conversion
                outputURL = try await converter.convert(
                    inputURL: file.url,
                    targetFormat: targetFormat,
                    progressHandler: { [weak self] progress in
                        Task { @MainActor in
                            if let self = self, index < self.files.count {
                                self.files[index].status = .converting(progress: 0.5 + progress * 0.5)
                            }
                        }
                    }
                )
            }

            files[index].outputURL = outputURL
            files[index].status = .completed

        } catch {
            files[index].status = .failed(error: error.localizedDescription)
        }

        // Clean up downloaded file after conversion (success or failure)
        if let downloadedFile = downloadedFileToCleanup {
            try? FileManager.default.removeItem(at: downloadedFile)
        }
    }
}
