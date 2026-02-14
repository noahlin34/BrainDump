import AppKit
import SwiftUI

struct NoteEditorView: View {
    @Environment(NoteStore.self) private var noteStore
    @Environment(AppState.self) private var appState

    let note: Note
    @State private var text: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var isPreviewMode: Bool = false
    @State private var keyMonitor: Any?
    @State private var holder = TextViewHolder()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    flushSave()
                    appState.currentMode = .savedNotes
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                Spacer()

                Button {
                    isPreviewMode.toggle()
                } label: {
                    Image(systemName: isPreviewMode ? "pencil" : "eye")
                }
                .buttonStyle(.plain)
                .help(isPreviewMode ? "Edit" : "Preview")

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([note.fileURL])
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.plain)
                .help("Show in Finder")

                ShareLink(item: text, preview: SharePreview("BrainDump Note")) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .help("Share")

                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)

            Divider()

            if isPreviewMode {
                markdownPreview
            } else {
                formattingToolbar
                Divider()
                MarkdownTextView(text: $text, holder: holder)
                    .padding(16)
                    .onChange(of: text) {
                        debounceSave()
                    }
            }
        }
        .onAppear {
            text = note.content
            installKeyMonitor()
        }
        .onDisappear {
            flushSave()
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

    // MARK: - Markdown Preview

    private var markdownPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    if line.isEmpty {
                        Spacer().frame(height: 12)
                    } else if line.hasPrefix("### ") {
                        Text(String(line.dropFirst(4)))
                            .font(.headline)
                            .padding(.vertical, 2)
                    } else if line.hasPrefix("## ") {
                        Text(String(line.dropFirst(3)))
                            .font(.title3.bold())
                            .padding(.vertical, 3)
                    } else if line.hasPrefix("# ") {
                        Text(String(line.dropFirst(2)))
                            .font(.title2.bold())
                            .padding(.vertical, 4)
                    } else {
                        Group {
                            if let attributed = try? AttributedString(markdown: line) {
                                Text(attributed)
                            } else {
                                Text(line)
                            }
                        }
                        .font(.body)
                        .padding(.vertical, 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .textSelection(.enabled)
        }
        .frame(maxHeight: .infinity)
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
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    // MARK: - Save Helpers

    private func debounceSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            noteStore.updateNote(note, content: text)
        }
    }

    private func flushSave() {
        saveTask?.cancel()
        if text != note.content {
            noteStore.updateNote(note, content: text)
        }
    }
}
