import Foundation

// MARK: - Video Downloader
class VideoDownloader: CommandLineConverter {
    
    func downloadVideo(
        from url: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        guard checkToolAvailability("yt-dlp") else {
            throw ConversionError.toolNotFound("yt-dlp (YouTube Downloader)")
        }
        
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalFileConverter_Downloads", isDirectory: true)
        
        try? FileManager.default.createDirectory(
            at: outputDir,
            withIntermediateDirectories: true
        )
        
        let outputTemplate = outputDir.appendingPathComponent("%(title)s.%(ext)s").path
        
        let arguments = [
            url,
            "-o", outputTemplate,
            "--no-playlist", // Download single video, not playlist
            "--format", "best[height<=1080]", // Max 1080p quality
            "--embed-metadata", // Keep metadata
            "--write-info-json" // Write info file
        ]
        
        let ytdlpPath = findExecutablePath("yt-dlp") ?? "/opt/homebrew/bin/yt-dlp"
        _ = try await runCommand(ytdlpPath, arguments: arguments, progressHandler: progressHandler)
        
        // Find the downloaded file
        let files = try FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
        let videoFiles = files.filter { file in
            let ext = file.pathExtension.lowercased()
            return ["mp4", "webm", "mkv", "avi", "mov"].contains(ext)
        }
        
        guard let downloadedFile = videoFiles.first else {
            throw ConversionError.conversionFailed("No video file found after download")
        }
        
        return downloadedFile
    }
    
    func getVideoInfo(from url: String) async throws -> VideoInfo {
        guard checkToolAvailability("yt-dlp") else {
            throw ConversionError.toolNotFound("yt-dlp")
        }
        
        let arguments = [
            url,
            "--dump-json",
            "--no-playlist"
        ]
        
        let ytdlpPath = findExecutablePath("yt-dlp") ?? "/opt/homebrew/bin/yt-dlp"
        let output = try await runCommand(ytdlpPath, arguments: arguments, progressHandler: { _ in })
        
        guard let data = output.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConversionError.conversionFailed("Failed to parse video info")
        }
        
        let title = json["title"] as? String ?? "Unknown"
        let duration = json["duration"] as? Double ?? 0
        let thumbnail = json["thumbnail"] as? String
        let uploader = json["uploader"] as? String ?? "Unknown"
        
        return VideoInfo(
            title: title,
            duration: duration,
            thumbnailURL: thumbnail,
            uploader: uploader
        )
    }
}

// MARK: - Video Info Model
struct VideoInfo {
    let title: String
    let duration: Double // in seconds
    let thumbnailURL: String?
    let uploader: String
    
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - URL Validation
extension VideoDownloader {
    static func isValidVideoURL(_ url: String) -> Bool {
        let supportedDomains = [
            "youtube.com", "youtu.be", "m.youtube.com",
            "instagram.com", "instagr.am",
            "tiktok.com", "vm.tiktok.com",
            "twitter.com", "x.com", "t.co",
            "facebook.com", "fb.watch",
            "vimeo.com",
            "dailymotion.com",
            "twitch.tv"
        ]
        
        guard let urlObj = URL(string: url) else { return false }
        guard let host = urlObj.host?.lowercased() else { return false }
        
        return supportedDomains.contains { domain in
            host.contains(domain)
        }
    }
}
