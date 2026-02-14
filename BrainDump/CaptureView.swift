import SwiftUI

struct CaptureView: View {
    @Environment(NoteStore.self) private var noteStore
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .font(.body)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(16)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("What's on your mind?")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 24)
                            .padding(.leading, 21)
                            .allowsHitTesting(false)
                    }
                }

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
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        noteStore.createNote(content: trimmed)
        text = ""
    }
}
