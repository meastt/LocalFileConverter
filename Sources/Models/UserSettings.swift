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
            print("Successfully set output directory to: \(url.path)")
        } catch {
            print("Failed to create bookmark: \(error)")
            // Clear any partial state
            outputDirectoryBookmark = nil
            outputDirectory = nil
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
                // Clear the stale bookmark instead of trying to recreate it
                // This prevents infinite recursion
                print("Bookmark is stale, clearing output directory")
                clearOutputDirectory()
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
            return "Default (Downloads/Converted Files)"
        }
    }
}
