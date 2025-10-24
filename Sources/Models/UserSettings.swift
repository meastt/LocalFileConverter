import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("outputDirectory") private var outputDirectoryBookmark: Data?
    @Published var outputDirectory: URL?

    private init() {
        loadOutputDirectory()
    }

    func setOutputDirectory(_ url: URL) {
        // Request permission to access the directory
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            outputDirectoryBookmark = bookmark
            outputDirectory = url
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    func loadOutputDirectory() {
        guard let bookmark = outputDirectoryBookmark else {
            outputDirectory = nil
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Recreate the bookmark
                setOutputDirectory(url)
            } else {
                outputDirectory = url
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
            outputDirectory = nil
        }
    }

    func clearOutputDirectory() {
        outputDirectoryBookmark = nil
        outputDirectory = nil
    }

    var outputDirectoryDisplayName: String {
        if let url = outputDirectory {
            return url.path
        } else {
            return "Default (Temporary Folder)"
        }
    }
}
