import SwiftUI

struct SavedNotesView: View {
    @Environment(NoteStore.self) private var noteStore
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            if noteStore.savedNotes.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("No saved notes yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Notes you keep during review will appear here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(noteStore.savedNotes) { note in
                        Button {
                            appState.currentMode = .editNote(note)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(firstLine(of: note.content))
                                    .font(.body)
                                    .lineLimit(1)
                                Text(note.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            noteStore.deleteSavedNote(noteStore.savedNotes[index])
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            noteStore.refresh()
        }
    }

    private func firstLine(of content: String) -> String {
        let line = content.components(separatedBy: .newlines).first ?? content
        return line.isEmpty ? "Untitled" : line
    }
}
