import Foundation

struct ConversionFile: Identifiable {
    let id = UUID()
    var url: URL
    let fileType: FileType
    var targetFormat: String?
    var status: ConversionStatus?
    var outputURL: URL?
    var imageProcessingOptions: ImageProcessingOptions?
    var videoProcessingOptions: VideoProcessingOptions?
    var metadata: [String: Any] = [:]

    var detectedFormats: [String] {
        fileType.supportedConversions
    }

    var fileSize: String {
        // Check if it's a remote URL
        if url.scheme == "http" || url.scheme == "https" {
            return "Remote file"
        }

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown size"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var iconName: String {
        switch fileType {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .document: return "doc.text"
        case .archive: return "archivebox"
        case .unknown: return "doc"
        }
    }
}

enum FileType {
    case image
    case video
    case audio
    case document
    case archive
    case unknown

    var supportedConversions: [String] {
        switch self {
        case .image:
            return ["jpg", "png", "heic", "tiff", "gif", "bmp", "webp", "pdf"]
        case .video:
            return ["mp4", "mov", "avi", "mkv", "webm", "gif"]
        case .audio:
            return ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
        case .document:
            return ["pdf", "epub", "mobi", "docx", "txt", "html"]
        case .archive:
            return ["zip", "7z", "tar", "tar.gz"]
        case .unknown:
            return []
        }
    }

    static func detect(from url: URL) -> FileType {
        let ext = url.pathExtension.lowercased()

        let imageFormats = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "gif", "bmp", "webp", "svg", "raw", "cr2", "nef", "arw"]
        let videoFormats = ["mp4", "mov", "avi", "mkv", "webm", "m4v", "flv", "wmv", "hevc"]
        let audioFormats = ["mp3", "wav", "flac", "aac", "ogg", "m4a", "alac", "wma", "opus"]
        let documentFormats = ["pdf", "epub", "mobi", "docx", "doc", "odt", "txt", "rtf", "html", "md"]
        let archiveFormats = ["zip", "7z", "rar", "tar", "gz", "bz2"]

        if imageFormats.contains(ext) { return .image }
        if videoFormats.contains(ext) { return .video }
        if audioFormats.contains(ext) { return .audio }
        if documentFormats.contains(ext) { return .document }
        if archiveFormats.contains(ext) { return .archive }

        return .unknown
    }
}

enum ConversionStatus {
    case converting(progress: Double)
    case completed
    case failed(error: String)

    var displayText: String {
        switch self {
        case .converting: return "Converting..."
        case .completed: return "Done"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .converting: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

import SwiftUI
extension Color {
    static let blue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let green = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let red = Color(red: 1.0, green: 0.23, blue: 0.19)
}
