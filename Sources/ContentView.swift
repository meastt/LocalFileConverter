import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var conversionManager = ConversionManager()
    @State private var selectedTool: ToolCategory?
    @State private var isDragging = false
    @State private var showingFilePicker = false
    @State private var showingURLInput = false
    @State private var videoURL = ""
    @State private var showingMissingToolsAlert = false
    @State private var missingTools: [String] = []

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedTool: $selectedTool, conversionManager: conversionManager)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            // Main Content Area
            ZStack {
                if conversionManager.files.isEmpty {
                    DashboardView(
                        selectedTool: $selectedTool,
                        isDragging: $isDragging,
                        showingFilePicker: $showingFilePicker,
                        showingURLInput: $showingURLInput,
                        conversionManager: conversionManager
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                } else {
                    WorkspaceView(
                        conversionManager: conversionManager,
                        isDragging: $isDragging,
                        showingFilePicker: $showingFilePicker,
                        showingURLInput: $showingURLInput
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingURLInput) {
            URLInputSheet(videoURL: $videoURL, conversionManager: conversionManager, isPresented: $showingURLInput)
        }
        .alert(conversionManager.alertTitle, isPresented: $conversionManager.showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(conversionManager.alertMessage)
        }
        .alert("Missing Required Tools", isPresented: $showingMissingToolsAlert) {
            Button("Copy Install Command", action: copyInstallCommand)
            Button("OK", role: .cancel) { }
        } message: {
            Text(missingToolsMessage)
        }
        .onAppear {
            checkForMissingTools()
        }
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

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            for url in urls {
                conversionManager.addFile(url: url)
            }
        } catch {
            print("File import error: \(error)")
        }
    }

    private func checkForMissingTools() {
        let requiredTools = ["ffmpeg", "magick", "pandoc", "7z", "yt-dlp"]
        let checker = CommandLineConverter()

        missingTools = requiredTools.filter { !checker.checkToolAvailability($0) }

        if !missingTools.isEmpty {
            // Show alert after a short delay to avoid showing immediately on launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingMissingToolsAlert = true
            }
        }
    }

    private var missingToolsMessage: String {
        let toolsList = missingTools.map { "• \($0)" }.joined(separator: "\n")
        return """
        The following tools are missing and required for full functionality:

        \(toolsList)

        Click "Copy Install Command" to copy the Homebrew installation command to your clipboard, then paste it into Terminal.
        """
    }

    private func copyInstallCommand() {
        let command = "brew install " + missingTools.joined(separator: " ")
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        #endif
    }
}

// MARK: - Tool Category
enum ToolCategory: String, CaseIterable, Identifiable {
    case all = "All Tools"
    case image = "Images"
    case video = "Videos"
    case audio = "Audio"
    case document = "Documents"
    case archive = "Archives"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .image: return "photo.on.rectangle.angled"
        case .video: return "video.badge.waveform"
        case .audio: return "waveform.badge.mic"
        case .document: return "doc.richtext"
        case .archive: return "archivebox.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .all:
            return LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .image:
            return LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .video:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .audio:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .document:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .archive:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var description: String {
        switch self {
        case .all: return "Convert any file type"
        case .image: return "JPEG, PNG, HEIC, WebP, PDF"
        case .video: return "MP4, MOV, AVI, MKV, WebM"
        case .audio: return "MP3, WAV, FLAC, AAC, OGG"
        case .document: return "PDF, EPUB, DOCX, HTML"
        case .archive: return "ZIP, 7Z, TAR, RAR"
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selectedTool: ToolCategory?
    @ObservedObject var conversionManager: ConversionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("File Converter")
                            .font(.system(size: 18, weight: .bold))
                        Text("Local & Private")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            Divider()

            // Tool Categories
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(ToolCategory.allCases) { category in
                        SidebarItem(
                            category: category,
                            isSelected: selectedTool == category
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTool = category
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()

            // Stats
            if !conversionManager.files.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                        Text("\(conversionManager.files.count) files")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    let completedCount = conversionManager.files.filter {
                        if case .completed = $0.status { return true }
                        return false
                    }.count

                    if completedCount > 0 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(completedCount) completed")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let category: ToolCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? category.gradient : .linearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom))
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(category.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(category.rawValue)
        .accessibilityHint("Select \(category.rawValue) conversion tool. \(category.description)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @Binding var selectedTool: ToolCategory?
    @Binding var isDragging: Bool
    @Binding var showingFilePicker: Bool
    @Binding var showingURLInput: Bool
    @ObservedObject var conversionManager: ConversionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: isDragging ? "arrow.down.circle.fill" : "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)

                    Text(isDragging ? "Drop Files Here!" : "Choose Your Tool")
                        .font(.system(size: 32, weight: .bold))

                    Text("Convert files locally without uploading to the cloud")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Quick Actions
                HStack(spacing: 16) {
                    QuickActionButton(
                        icon: "folder.badge.plus",
                        title: "Browse Files",
                        color: .blue
                    ) {
                        showingFilePicker = true
                    }

                    QuickActionButton(
                        icon: "link.badge.plus",
                        title: "Paste URL",
                        color: .purple
                    ) {
                        showingURLInput = true
                    }
                }
                .padding(.horizontal, 40)

                // Tool Categories Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 20) {
                    ForEach(ToolCategory.allCases) { category in
                        ToolCategoryCard(category: category)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedTool = category
                                }
                                showingFilePicker = true
                            }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: isDragging ? [10] : [])
                        )
                        .foregroundColor(isDragging ? .accentColor : .clear)
                        .animation(.easeInOut(duration: 0.3), value: isDragging)
                )
        )
        .padding()
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(isHovered ? 0.2 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(isHovered ? 0.5 : 0.3), lineWidth: 1.5)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityHint("Opens \(title.lowercased()) dialog")
    }
}

// MARK: - Tool Category Card
struct ToolCategoryCard: View {
    let category: ToolCategory
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(category.gradient)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 18, weight: .semibold))

                Text(category.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(20)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 12 : 6, y: isHovered ? 6 : 3)
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue) converter")
        .accessibilityHint("Select to convert \(category.description)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Workspace View
struct WorkspaceView: View {
    @ObservedObject var conversionManager: ConversionManager
    @Binding var isDragging: Bool
    @Binding var showingFilePicker: Bool
    @Binding var showingURLInput: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: { showingFilePicker = true }) {
                    Label("Add Files", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("o", modifiers: .command)
                .accessibilityLabel("Add Files")
                .accessibilityHint("Browse and select files to convert. Shortcut: Command O")

                Button(action: { showingURLInput = true }) {
                    Label("Add URL", systemImage: "link")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("u", modifiers: .command)
                .accessibilityLabel("Add URL")
                .accessibilityHint("Download video from URL. Shortcut: Command U")

                Spacer()

                Button(action: { conversionManager.clearAll() }) {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .keyboardShortcut("k", modifiers: .command)
                .accessibilityLabel("Clear All")
                .accessibilityHint("Remove all files from the list. Shortcut: Command K")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            // File List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversionManager.files) { file in
                        EnhancedFileRowView(file: file, conversionManager: conversionManager)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    .onMove { from, to in
                        conversionManager.moveFiles(from: from, to: to)
                    }
                }
                .padding(20)
            }

            // Footer Actions
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(conversionManager.files.count) files")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Ready to convert")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Convert All") {
                    conversionManager.convertAll()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(conversionManager.isConverting)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel(conversionManager.isConverting ? "Converting files" : "Convert all files")
                .accessibilityHint("Start converting all files in the list. Shortcut: Command Return")
                .accessibilityValue(conversionManager.isConverting ? "In progress" : "Ready")
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDragging ? Color.accentColor : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
        )
    }
}

// MARK: - Enhanced File Row View
struct EnhancedFileRowView: View {
    let file: ConversionFile
    @ObservedObject var conversionManager: ConversionManager
    @State private var isHovered = false
    @State private var showingOptions = false

    var body: some View {
        HStack(spacing: 16) {
            // File Icon with Gradient Background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(file.fileType.gradient)
                    .frame(width: 56, height: 56)

                Image(systemName: file.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .accessibilityHidden(true)

            // File Info
            VStack(alignment: .leading, spacing: 6) {
                Text(file.url.lastPathComponent)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(file.fileSize, systemImage: "archivebox")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if let status = file.status {
                        EnhancedStatusBadge(status: status)
                    }
                }
            }

            Spacer()

            // Format Selector or Actions
            if file.status == nil || file.status?.isFailed == true {
                Menu {
                    ForEach(file.detectedFormats, id: \.self) { format in
                        Button(format.uppercased()) {
                            conversionManager.setTargetFormat(for: file.id, format: format)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("→ \(file.targetFormat?.uppercased() ?? "FORMAT")")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Output format: \(file.targetFormat?.uppercased() ?? "not selected")")
                .accessibilityHint("Select output format for conversion")
            }

            // Progress or Result Actions
            if let status = file.status {
                switch status {
                case .converting(let progress):
                    VStack(spacing: 6) {
                        ProgressView(value: progress)
                            .frame(width: 120)
                            .accessibilityLabel("Conversion progress")
                            .accessibilityValue("\(Int(progress * 100)) percent complete")
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }

                case .completed:
                    HStack(spacing: 8) {
                        Button(action: {
                            if let outputURL = file.outputURL {
                                NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                            }
                        }) {
                            Label("Show", systemImage: "folder")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Show in Finder")
                        .accessibilityHint("Opens Finder and selects the converted file")
                    }

                case .failed(let error):
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 150)

                        Button("Retry") {
                            conversionManager.retryFile(id: file.id)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Retry conversion")
                        .accessibilityHint("Attempts to convert the file again")
                    }
                }
            }

            // Remove Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    conversionManager.removeFile(id: file.id)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0.3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove file")
            .accessibilityHint("Remove \(file.url.lastPathComponent) from the conversion list")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 8 : 4, y: 2)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Enhanced Status Badge
struct EnhancedStatusBadge: View {
    let status: ConversionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(status.displayText)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.2))
        )
        .overlay(
            Capsule()
                .strokeBorder(status.color.opacity(0.5), lineWidth: 1)
        )
        .foregroundColor(status.color)
    }
}

// MARK: - URL Input Sheet
struct URLInputSheet: View {
    @Binding var videoURL: String
    @ObservedObject var conversionManager: ConversionManager
    @Binding var isPresented: Bool
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Download from URL")
                        .font(.system(size: 20, weight: .bold))
                    Text("Paste a video URL from YouTube, Instagram, TikTok, etc.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // URL Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://www.youtube.com/watch?v=...", text: $videoURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

                Text("Supported: YouTube, Instagram, TikTok, Twitter, Facebook, Vimeo, and more")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    isPresented = false
                    videoURL = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Download") {
                    Task {
                        isLoading = true
                        await conversionManager.addVideoURL(videoURL)
                        isLoading = false
                        isPresented = false
                        videoURL = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(videoURL.isEmpty || isLoading)
                .keyboardShortcut(.defaultAction)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}

// MARK: - Extensions
extension FileType {
    var gradient: LinearGradient {
        switch self {
        case .image:
            return LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .video:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .audio:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .document:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .archive:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .unknown:
            return LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
        }
    }
}

extension ConversionStatus {
    var iconName: String {
        switch self {
        case .converting: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}
