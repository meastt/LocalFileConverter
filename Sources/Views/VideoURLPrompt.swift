import AppKit

class VideoURLPrompt {

    private class PasteHelper {
        var textField: NSTextField?
        var urlLabel: NSTextField?

        @objc func pasteAction() {
            if let string = NSPasteboard.general.string(forType: .string) {
                textField?.stringValue = string
                urlLabel?.stringValue = "URL from clipboard: \(string)"
                // Force redraw
                textField?.needsDisplay = true
                textField?.setNeedsDisplay(textField?.bounds ?? .zero)
            }
        }
    }

    static func show(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Video Downloader"
            alert.informativeText = "Enter a video URL from YouTube, Instagram, TikTok, Twitter, Facebook, Vimeo, or other supported platforms.\n\nIf typing doesn't work, click 'Paste from Clipboard'"
            alert.alertStyle = .informational

            // Create text field
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
            textField.placeholderString = "https://www.youtube.com/watch?v=..."
            textField.stringValue = ""
            textField.isEditable = true
            textField.isEnabled = true
            textField.isSelectable = true

            // Label to show the pasted URL (workaround for TextField rendering issue)
            let urlLabel = NSTextField(labelWithString: "")
            urlLabel.font = NSFont.systemFont(ofSize: 11)
            urlLabel.textColor = .secondaryLabelColor
            urlLabel.lineBreakMode = .byTruncatingMiddle
            urlLabel.maximumNumberOfLines = 2

            // Try to get from pasteboard automatically
            if let pasteboardString = NSPasteboard.general.string(forType: .string),
               pasteboardString.starts(with: "http") {
                textField.stringValue = pasteboardString
                urlLabel.stringValue = "URL from clipboard: \(pasteboardString)"
            }

            // Add a button to paste from clipboard
            let pasteButton = NSButton(title: "Paste from Clipboard", target: nil, action: nil)
            pasteButton.bezelStyle = .rounded

            let helper = PasteHelper()
            helper.textField = textField
            helper.urlLabel = urlLabel
            pasteButton.target = helper
            pasteButton.action = #selector(PasteHelper.pasteAction)

            // Keep helper alive by storing in alert's associated objects
            objc_setAssociatedObject(alert, "helper", helper, .OBJC_ASSOCIATION_RETAIN)

            let stackView = NSStackView(views: [textField, pasteButton, urlLabel])
            stackView.orientation = .vertical
            stackView.spacing = 8
            stackView.alignment = .leading
            stackView.frame = NSRect(x: 0, y: 0, width: 400, height: 90)

            alert.accessoryView = stackView
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Cancel")

            // Make text field first responder when alert appears
            alert.window.initialFirstResponder = textField

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                let url = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.isEmpty {
                    completion(url)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}
