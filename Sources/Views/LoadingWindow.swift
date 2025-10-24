import AppKit

class LoadingWindow {
    private var window: NSWindow?
    private var progressIndicator: NSProgressIndicator?
    private static var activeWindows: [LoadingWindow] = [] // Keep strong references

    func show(message: String) {
        LoadingWindow.activeWindows.append(self)

        if Thread.isMainThread {
            self.createAndShowWindow(message: message)
        } else {
            DispatchQueue.main.sync {
                self.createAndShowWindow(message: message)
            }
        }
    }

    private func createAndShowWindow(message: String) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.title = ""
        panel.isMovableByWindowBackground = true
        panel.center()
        panel.level = .modalPanel // Changed from .floating to appear on top of everything
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        panel.hasShadow = true

        // Make sure it's on the active space
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 16
        stackView.alignment = .centerX
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.alignment = .center
        label.textColor = .white
        label.backgroundColor = .clear
        label.isBordered = false

        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.appearance = NSAppearance(named: .darkAqua) // Make spinner visible on dark background
        spinner.startAnimation(nil)

        stackView.addArrangedSubview(spinner)
        stackView.addArrangedSubview(label)

        panel.contentView?.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: panel.contentView!.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: panel.contentView!.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 250)
        ])

        self.window = panel
        self.progressIndicator = spinner
        panel.makeKeyAndOrderFront(nil)
        panel.display()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        DispatchQueue.main.async {
            self.progressIndicator?.stopAnimation(nil)
            self.window?.orderOut(nil)
            self.window?.close()
            self.window = nil
            self.progressIndicator = nil
            LoadingWindow.activeWindows.removeAll { $0 === self }
        }
    }
}
