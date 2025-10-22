import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var conversionManager = ConversionManager()
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()

            // Main Content
            if conversionManager.files.isEmpty {
                DropZoneView(isDragging: $isDragging)
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
            } else {
                FileListView(conversionManager: conversionManager)
            }

            // Footer with actions
            if !conversionManager.files.isEmpty {
                FooterView(conversionManager: conversionManager)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }

                DispatchQueue.main.async {
                    conversionManager.addFile(url: url)
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                Text("Local File Converter")
                    .font(.system(size: 28, weight: .bold))
            }
            .padding(.top, 30)

            Text("Convert files locally without uploading to sketchy websites")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Drop Zone View
struct DropZoneView: View {
    @Binding var isDragging: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 60))
                .foregroundColor(isDragging ? .accentColor : .secondary)

            Text("Drag & Drop Files Here")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Or click to browse")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Supported formats
            VStack(alignment: .leading, spacing: 8) {
                FormatRow(icon: "photo", text: "Images: JPEG, PNG, HEIC, TIFF, GIF, BMP, WebP, SVG")
                FormatRow(icon: "video", text: "Video: MP4, MOV, AVI, MKV, WebM, HEVC")
                FormatRow(icon: "waveform", text: "Audio: MP3, WAV, FLAC, AAC, OGG, ALAC")
                FormatRow(icon: "doc", text: "Documents: PDF, EPUB, MOBI, DOCX, ODT")
                FormatRow(icon: "archivebox", text: "Archives: ZIP, 7Z, RAR")
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDragging ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [10])
                        )
                        .foregroundColor(isDragging ? .accentColor : .secondary.opacity(0.5))
                )
        )
        .padding(40)
    }
}

struct FormatRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - File List View
struct FileListView: View {
    @ObservedObject var conversionManager: ConversionManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(conversionManager.files) { file in
                    FileRowView(file: file, conversionManager: conversionManager)
                }
            }
            .padding()
        }
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let file: ConversionFile
    @ObservedObject var conversionManager: ConversionManager

    var body: some View {
        HStack(spacing: 16) {
            // File icon
            Image(systemName: file.iconName)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.url.lastPathComponent)
                    .font(.system(size: 14, weight: .medium))

                HStack(spacing: 8) {
                    Text(file.fileSize)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if let status = file.status {
                        StatusBadge(status: status)
                    }
                }
            }

            Spacer()

            // Output format picker
            if file.status == nil || file.status == .failed {
                Picker("Convert to", selection: Binding(
                    get: { file.targetFormat ?? file.detectedFormats.first ?? "" },
                    set: { newValue in
                        conversionManager.setTargetFormat(for: file.id, format: newValue)
                    }
                )) {
                    ForEach(file.detectedFormats, id: \.self) { format in
                        Text(format.uppercased()).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            // Progress or action button
            if let status = file.status {
                switch status {
                case .converting(let progress):
                    ProgressView(value: progress)
                        .frame(width: 100)
                case .completed:
                    Button("Show") {
                        if let outputURL = file.outputURL {
                            NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: "")
                        }
                    }
                    .buttonStyle(.bordered)
                case .failed(let error):
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .frame(maxWidth: 150)
                        .lineLimit(2)
                }
            }

            // Remove button
            Button(action: {
                conversionManager.removeFile(id: file.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct StatusBadge: View {
    let status: ConversionStatus

    var body: some View {
        Text(status.displayText)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color)
            .cornerRadius(4)
    }
}

// MARK: - Footer View
struct FooterView: View {
    @ObservedObject var conversionManager: ConversionManager

    var body: some View {
        HStack {
            Button("Clear All") {
                conversionManager.clearAll()
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("\(conversionManager.files.count) file(s)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button("Convert All") {
                conversionManager.convertAll()
            }
            .buttonStyle(.borderedProminent)
            .disabled(conversionManager.isConverting)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
