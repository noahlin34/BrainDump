import AppKit
import SwiftUI

struct CaptureView: View {
    @Environment(NoteStore.self) private var noteStore
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            formattingToolbar
            Divider()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.body)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)

                if text.isEmpty {
                    Text("What's on your mind?")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 5)
                        .padding(.top, 1)
                        .allowsHitTesting(false)
                }
            }
            .padding(16)

            Divider()

            HStack {
                Text("⌘ Enter to save")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(12)
        }
        .onAppear {
            isFocused = true
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    // MARK: - Formatting Toolbar

    private var formattingToolbar: some View {
        HStack(spacing: 12) {
            Button { applyMarkdown(prefix: "**", suffix: "**") } label: {
                Image(systemName: "bold")
                    .frame(width: 28, height: 24)
            }
            .help("Bold (⌘B)")

            Button { applyMarkdown(prefix: "_", suffix: "_") } label: {
                Image(systemName: "italic")
                    .frame(width: 28, height: 24)
            }
            .help("Italic (⌘I)")

            Button { applyMarkdown(prefix: "# ", suffix: "") } label: {
                Image(systemName: "number")
                    .frame(width: 28, height: 24)
            }
            .help("Heading")

            Button { applyMarkdown(prefix: "- ", suffix: "") } label: {
                Image(systemName: "list.bullet")
                    .frame(width: 28, height: 24)
            }
            .help("List")

            Button { applyMarkdown(prefix: "`", suffix: "`") } label: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .frame(width: 28, height: 24)
            }
            .help("Code")

            Spacer()
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Markdown Helpers

    private func applyMarkdown(prefix: String, suffix: String) {
        guard let textView = Self.findTextView() else { return }
        let range = textView.selectedRange()
        let selected = (textView.string as NSString).substring(with: range)
        textView.insertText(prefix + selected + suffix, replacementRange: range)
        textView.window?.makeFirstResponder(textView)
    }

    private static func findTextView() -> NSTextView? {
        for window in NSApp.windows {
            if let found = findTextView(in: window.contentView) {
                return found
            }
        }
        return nil
    }

    private static func findTextView(in view: NSView?) -> NSTextView? {
        guard let view else { return nil }
        if let textView = view as? NSTextView, !textView.isFieldEditor {
            return textView
        }
        for subview in view.subviews {
            if let found = findTextView(in: subview) {
                return found
            }
        }
        return nil
    }

    // MARK: - Keyboard Shortcuts

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  let chars = event.charactersIgnoringModifiers else { return event }
            let prefix: String
            let suffix: String
            switch chars {
            case "b": prefix = "**"; suffix = "**"
            case "i": prefix = "_"; suffix = "_"
            default: return event
            }
            guard let textView = Self.findTextView() else { return event }
            let range = textView.selectedRange()
            let selected = (textView.string as NSString).substring(with: range)
            textView.insertText(prefix + selected + suffix, replacementRange: range)
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    // MARK: - Save

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        noteStore.createNote(content: trimmed)
        text = ""
    }
}
