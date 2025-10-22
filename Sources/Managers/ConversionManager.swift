import Foundation
import Combine

@MainActor
class ConversionManager: ObservableObject {
    @Published var files: [ConversionFile] = []
    @Published var isConverting = false

    private var converters: [FileType: any FileConverter] = [:]

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

    func convertAll() {
        Task {
            isConverting = true
            defer { isConverting = false }

            for i in files.indices {
                guard files[i].status == nil || files[i].status?.displayText == "Failed" else {
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

        guard let converter = converters[file.fileType] else {
            files[index].status = .failed(error: "No converter available")
            return
        }

        do {
            // Update progress periodically
            files[index].status = .converting(progress: 0.3)

            let outputURL = try await converter.convert(
                inputURL: file.url,
                targetFormat: targetFormat,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        if let self = self, index < self.files.count {
                            self.files[index].status = .converting(progress: progress)
                        }
                    }
                }
            )

            files[index].outputURL = outputURL
            files[index].status = .completed

        } catch {
            files[index].status = .failed(error: error.localizedDescription)
        }
    }
}
