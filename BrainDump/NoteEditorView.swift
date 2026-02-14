import SwiftUI

struct NoteEditorView: View {
    @Environment(NoteStore.self) private var noteStore
    @Environment(AppState.self) private var appState

    let note: Note
    @State private var text: String = ""
    @State private var saveTask: Task<Void, Never>?

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
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)

            Divider()

            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(16)
                .onChange(of: text) {
                    debounceSave()
                }
        }
        .onAppear {
            text = note.content
        }
        .onDisappear {
            flushSave()
        }
    }

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
