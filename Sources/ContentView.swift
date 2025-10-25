import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var conversionManager = ConversionManager()
    @State private var selectedTool: ToolCategory?
    @State private var isDragging = false
    @State private var showingFilePicker = false
    @State private var showingURLInput = false
    @State private var videoURL = ""
    @State private var showingLoadingOverlay = false
    @State private var loadingMessage = ""
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
                if selectedTool == .settings {
                    SettingsView()
                } else if let tool = selectedTool, tool != .all {
                    // Show dedicated tool screen for each category
                    ToolCategoryView(
                        category: tool,
                        conversionManager: conversionManager,
                        isDragging: $isDragging,
                        showingFilePicker: $showingFilePicker,
                        showingURLInput: $showingURLInput,
                        showingLoadingOverlay: $showingLoadingOverlay,
                        loadingMessage: $loadingMessage
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                } else if conversionManager.files.isEmpty {
                    // Show main dashboard only when no tool is selected and no files
                    DashboardView(
                        selectedTool: $selectedTool,
                        isDragging: $isDragging,
                        showingFilePicker: $showingFilePicker,
                        showingURLInput: $showingURLInput,
                        conversionManager: conversionManager,
                        showingLoadingOverlay: $showingLoadingOverlay,
                        loadingMessage: $loadingMessage
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                } else {
                    // Show workspace when files are present
                    WorkspaceView(
                        conversionManager: conversionManager,
                        isDragging: $isDragging,
                        showingFilePicker: $showingFilePicker,
                        showingURLInput: $showingURLInput,
                        selectedTool: selectedTool,
                        showingLoadingOverlay: $showingLoadingOverlay,
                        loadingMessage: $loadingMessage
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                }
            }

            // Loading Overlay
            if showingLoadingOverlay {
                LoadingOverlay(message: loadingMessage)
                    .transition(.opacity)
                    .zIndex(999)
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
                .interactiveDismissDisabled(false)
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
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .image: return "photo.on.rectangle.angled"
        case .video: return "video.badge.waveform"
        case .audio: return "waveform.badge.mic"
        case .document: return "doc.richtext"
        case .archive: return "archivebox.fill"
        case .settings: return "gearshape.fill"
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
        case .settings:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
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
        case .settings: return "Configure app preferences"
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
                            withAnimation(.easeInOut(duration: 0.2)) {
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
    @Binding var showingLoadingOverlay: Bool
    @Binding var loadingMessage: String

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    if let tool = selectedTool, tool != .all {
                        Image(systemName: isDragging ? "arrow.down.circle.fill" : tool.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(isDragging ? .linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) : tool.gradient)
                            .scaleEffect(isDragging ? 1.1 : 1.0)
                            .animation(.none, value: isDragging)

                        Text(isDragging ? "Drop \(tool.rawValue) Files Here!" : tool.rawValue)
                            .font(.system(size: 32, weight: .bold))

                        Text(tool.description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Image(systemName: isDragging ? "arrow.down.circle.fill" : "sparkles")
                            .font(.system(size: 56))
                            .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .scaleEffect(isDragging ? 1.1 : 1.0)
                            .animation(.none, value: isDragging)

                        Text(isDragging ? "Drop Files Here!" : "Choose Your Tool")
                            .font(.system(size: 32, weight: .bold))

                        Text("Convert files locally without uploading to the cloud")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
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
                        title: "Video Downloader",
                        color: .purple
                    ) {
                        VideoURLPrompt.show { url in
                            if let url = url {
                                Task { @MainActor in
                                    withAnimation {
                                        loadingMessage = "Fetching video info..."
                                        showingLoadingOverlay = true
                                    }

                                    let startTime = Date()
                                    await conversionManager.addVideoURL(url)
                                    let elapsed = Date().timeIntervalSince(startTime)
                                    let minimumDisplayTime = 0.5
                                    if elapsed < minimumDisplayTime {
                                        try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
                                    }

                                    withAnimation {
                                        showingLoadingOverlay = false
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)

                // Tool Categories Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 20) {
                    ForEach(ToolCategory.allCases.filter { $0 != .settings }) { category in
                        ToolCategoryCard(category: category)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTool = category
                                }
                                // Don't open file picker immediately - let user explore the tool screen first
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
            .animation(.easeInOut(duration: 0.15), value: isHovered)
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
    var selectedTool: ToolCategory?
    @Binding var showingLoadingOverlay: Bool
    @Binding var loadingMessage: String

    var filteredFiles: [ConversionFile] {
        guard let tool = selectedTool, tool != .all else {
            return conversionManager.files
        }

        return conversionManager.files.filter { file in
            switch tool {
            case .image: return file.fileType == .image
            case .video: return file.fileType == .video
            case .audio: return file.fileType == .audio
            case .document: return file.fileType == .document
            case .archive: return file.fileType == .archive
            default: return true
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Tool Category Indicator
                if let tool = selectedTool, tool != .all {
                    HStack(spacing: 8) {
                        Image(systemName: tool.icon)
                            .foregroundStyle(tool.gradient)
                        Text(tool.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }

                Spacer()

                Button(action: { showingFilePicker = true }) {
                    Label("Add Files", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("o", modifiers: .command)
                .accessibilityLabel("Add Files")
                .accessibilityHint("Browse and select files to convert. Shortcut: Command O")

                Button(action: {
                    VideoURLPrompt.show { url in
                        if let url = url {
                            Task { @MainActor in
                                withAnimation {
                                    loadingMessage = "Fetching video info..."
                                    showingLoadingOverlay = true
                                }

                                let startTime = Date()
                                await conversionManager.addVideoURL(url)
                                let elapsed = Date().timeIntervalSince(startTime)
                                let minimumDisplayTime = 0.5
                                if elapsed < minimumDisplayTime {
                                    try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
                                }

                                withAnimation {
                                    showingLoadingOverlay = false
                                }
                            }
                        }
                    }
                }) {
                    Label("Add URL", systemImage: "link")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("u", modifiers: .command)
                .accessibilityLabel("Add URL")
                .accessibilityHint("Download video from URL. Shortcut: Command U")

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
                if filteredFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedTool?.icon ?? "doc.on.doc")
                            .font(.system(size: 48))
                            .foregroundStyle(selectedTool?.gradient ?? .linearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                            .padding(.top, 60)

                        Text("No \(selectedTool?.rawValue.lowercased() ?? "files") found")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Add files or switch to a different category")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredFiles) { file in
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
            }

            // Footer Actions
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if selectedTool == nil || selectedTool == .all {
                        Text("\(conversionManager.files.count) files")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text("\(filteredFiles.count) of \(conversionManager.files.count) files")
                            .font(.system(size: 16, weight: .semibold))
                    }
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
                .disabled(conversionManager.isConverting || filteredFiles.isEmpty)
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
                            .lineLimit(3)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 250)
                            .help(error)

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
    @State private var localURL: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Downloader")
                        .font(.system(size: 20, weight: .bold))
                    Text("Download videos from popular social platforms")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // URL Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Video URL")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                MacOSTextField(text: $localURL, placeholder: "https://www.youtube.com/watch?v=...")
                    .frame(height: 32)
                    .onAppear {
                        print("TextField appeared in sheet")
                    }

                Text("Supported: YouTube, Instagram, TikTok, Twitter, Facebook, Vimeo, and more")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    isPresented = false
                    localURL = ""
                    videoURL = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Download") {
                    Task {
                        isLoading = true
                        await conversionManager.addVideoURL(localURL)
                        isLoading = false
                        isPresented = false
                        videoURL = localURL
                        localURL = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(localURL.isEmpty || isLoading)
                .keyboardShortcut(.defaultAction)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        .padding(24)
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            localURL = videoURL
            print("URL Input Sheet appeared")
            print("Initial URL value: '\(localURL)'")
        }
    }
}

// MARK: - macOS NSTextField Wrapper
struct MacOSTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    class CustomTextField: NSTextField {
        override var acceptsFirstResponder: Bool { true }
        override var canBecomeKeyView: Bool { true }

        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            print("TextField becomeFirstResponder: \(result)")
            return result
        }
    }

    func makeNSView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.isEditable = true
        textField.isSelectable = true
        textField.refusesFirstResponder = false
        textField.allowsEditingTextAttributes = false

        print("Creating NSTextField - editable: \(textField.isEditable), selectable: \(textField.isSelectable)")

        // Try to make it first responder immediately
        DispatchQueue.main.async {
            if let window = textField.window {
                print("Window found, making textField first responder")
                window.makeFirstResponder(textField)
            } else {
                print("No window yet")
            }
        }

        return textField
    }

    func updateNSView(_ nsView: CustomTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        // Ensure it's editable and try to grab focus
        nsView.isEditable = true
        nsView.isSelectable = true

        // Try making it first responder on update too
        if !context.coordinator.didBecomeFirstResponder {
            DispatchQueue.main.async {
                if let window = nsView.window {
                    let success = window.makeFirstResponder(nsView)
                    print("makeFirstResponder result: \(success)")
                    context.coordinator.didBecomeFirstResponder = success
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MacOSTextField
        var didBecomeFirstResponder = false

        init(_ parent: MacOSTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            print("Text changed to: '\(textField.stringValue)'")
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("Command: \(commandSelector)")
            return false
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var settings = UserSettings.shared
    @State private var showingFolderPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.linearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing))

                        Text("Settings")
                            .font(.system(size: 32, weight: .bold))
                    }
                    Text("Configure your file converter preferences")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Divider()

                // Output Directory Setting
                VStack(alignment: .leading, spacing: 16) {
                    Text("Output Directory")
                        .font(.system(size: 20, weight: .semibold))

                    Text("Choose where converted files will be saved. If not set, files will be saved to a temporary folder.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Location:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(settings.outputDirectoryDisplayName)
                                .font(.system(size: 14))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }

                        VStack(spacing: 8) {
                            Button(action: {
                                showingFolderPicker = true
                            }) {
                                Label("Choose Folder", systemImage: "folder.badge.plus")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .buttonStyle(.borderedProminent)

                            if settings.outputDirectory != nil {
                                Button(action: {
                                    settings.clearOutputDirectory()
                                }) {
                                    Label("Reset to Default", systemImage: "arrow.counterclockwise")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Divider()

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.system(size: 20, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version:")
                                .foregroundColor(.secondary)
                            Text("1.0.0")
                        }
                        .font(.system(size: 14))

                        HStack {
                            Text("Privacy:")
                                .foregroundColor(.secondary)
                            Text("All conversions happen locally on your device")
                        }
                        .font(.system(size: 14))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                let url = try result.get().first
                if let url = url {
                    settings.setOutputDirectory(url)
                }
            } catch {
                print("Failed to select folder: \(error)")
            }
        }
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

// MARK: - Tool Category View
struct ToolCategoryView: View {
    let category: ToolCategory
    @ObservedObject var conversionManager: ConversionManager
    @Binding var isDragging: Bool
    @Binding var showingFilePicker: Bool
    @Binding var showingURLInput: Bool
    @Binding var showingLoadingOverlay: Bool
    @Binding var loadingMessage: String
    
    var filteredFiles: [ConversionFile] {
        return conversionManager.files.filter { file in
            switch category {
            case .image: return file.fileType == .image
            case .video: return file.fileType == .video
            case .audio: return file.fileType == .audio
            case .document: return file.fileType == .document
            case .archive: return file.fileType == .archive
            default: return true
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: isDragging ? "arrow.down.circle.fill" : category.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(isDragging ? .linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) : category.gradient)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .animation(.none, value: isDragging)
                    
                    Text(isDragging ? "Drop \(category.rawValue) Here!" : category.rawValue)
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(category.description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: { showingFilePicker = true }) {
                        Label("Add \(category.rawValue)", systemImage: "folder.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(category.gradient)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("o", modifiers: .command)
                    .accessibilityLabel("Add \(category.rawValue)")
                    .accessibilityHint("Browse and select \(category.rawValue.lowercased()) files to convert")
                    
                    if category == .video {
                        Button(action: {
                            VideoURLPrompt.show { url in
                                if let url = url {
                                    Task { @MainActor in
                                        withAnimation {
                                            loadingMessage = "Fetching video info..."
                                            showingLoadingOverlay = true
                                        }
                                        
                                        let startTime = Date()
                                        await conversionManager.addVideoURL(url)
                                        let elapsed = Date().timeIntervalSince(startTime)
                                        let minimumDisplayTime = 0.5
                                        if elapsed < minimumDisplayTime {
                                            try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
                                        }
                                        
                                        withAnimation {
                                            showingLoadingOverlay = false
                                        }
                                    }
                                }
                            }
                        }) {
                            Label("Add Video URL", systemImage: "link.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("u", modifiers: .command)
                        .accessibilityLabel("Add Video URL")
                        .accessibilityHint("Download video from URL")
                    }
                }
                .padding(.horizontal, 40)
                
                // Files Section
                if !filteredFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(filteredFiles.count) \(category.rawValue.lowercased()) files")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Spacer()
                            
                            Button(action: { conversionManager.clearAll() }) {
                                Label("Clear All", systemImage: "trash")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .keyboardShortcut("k", modifiers: .command)
                            .accessibilityLabel("Clear All")
                            .accessibilityHint("Remove all files from the list")
                        }
                        
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFiles) { file in
                                EnhancedFileRowView(file: file, conversionManager: conversionManager)
                            }
                        }
                        
                        // Convert Button
                        Button(action: {
                            Task {
                                conversionManager.convertAll()
                            }
                        }) {
                            Label("Convert All \(category.rawValue)", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(category.gradient)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .disabled(conversionManager.isConverting || filteredFiles.isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                        .accessibilityLabel(conversionManager.isConverting ? "Converting files" : "Convert all files")
                        .accessibilityHint("Start converting all files in the list")
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: category.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(category.gradient)
                            .opacity(0.6)
                        
                        Text("No \(category.rawValue.lowercased()) files yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Add files to get started with \(category.rawValue.lowercased()) conversion")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
