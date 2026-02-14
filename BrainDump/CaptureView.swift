import AppKit
import SwiftUI

struct CaptureView: View {
    @Environment(NoteStore.self) private var noteStore
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @State private var keyMonitor: Any?
    @State private var holder = TextViewHolder()

    var body: some View {
        VStack(spacing: 0) {
            formattingToolbar
            Divider()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.body)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(TextViewIntrospect(holder: holder))

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
        .onReceive(NotificationCenter.default.publisher(for: .markdownInserted)) { notification in
            if let tv = notification.object as? NSTextView, tv === holder.textView {
                text = tv.string
            }
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
        guard let tv = holder.textView else { return }
        let range = tv.selectedRange()
        let selected = (tv.string as NSString).substring(with: range)
        if selected.isEmpty && !suffix.isEmpty {
            tv.insertText(prefix + suffix, replacementRange: range)
            tv.setSelectedRange(NSRange(location: range.location + prefix.count, length: 0))
        } else {
            tv.insertText(prefix + selected + suffix, replacementRange: range)
        }
        text = tv.string
        tv.window?.makeFirstResponder(tv)
    }

    // MARK: - Keyboard Shortcuts

    private func installKeyMonitor() {
        let holder = self.holder
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
            guard let tv = holder.textView else { return event }
            let range = tv.selectedRange()
            let selected = (tv.string as NSString).substring(with: range)
            if selected.isEmpty {
                tv.insertText(prefix + suffix, replacementRange: range)
                tv.setSelectedRange(NSRange(location: range.location + prefix.count, length: 0))
            } else {
                tv.insertText(prefix + selected + suffix, replacementRange: range)
            }
            NotificationCenter.default.post(name: .markdownInserted, object: tv)
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
