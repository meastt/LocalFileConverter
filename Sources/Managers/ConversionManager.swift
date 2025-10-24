import Foundation
import Combine

@MainActor
class ConversionManager: ObservableObject {
    @Published var files: [ConversionFile] = []
    @Published var isConverting = false

    private var converters: [FileType: any FileConverter] = [:]
    private let videoDownloader = VideoDownloader()

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
            print("Unsupported file type: \(url.lastPathComponent)")
            return
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

    func convertAll() {
        Task {
            isConverting = true
            defer { isConverting = false }

            for i in files.indices {
                guard files[i].status == nil || files[i].status?.isFailed == true else {
                    continue
                }

                await convertFile(at: i)
            }
        }
    }

    private func convertFile(at index: Int) async {
        guard index < files.count else { return }

        let file = files[index]
        guard let targetFormat = file.targetFormat else { return }

        files[index].status = .converting(progress: 0.0)

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
    }
}
