import SwiftUI

struct ReviewView: View {
    @Environment(NoteStore.self) private var noteStore

    @State private var currentIndex = 0

    private var remainingNotes: [Note] {
        noteStore.inboxNotes
    }

    var body: some View {
        VStack(spacing: 16) {
            if currentIndex < remainingNotes.count {
                let note = remainingNotes[currentIndex]

                Text("\(remainingNotes.count - currentIndex) notes to review")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                NoteCardView(
                    note: note,
                    onSave: {
                        noteStore.saveNote(note)
                        currentIndex = 0
                    },
                    onDelete: {
                        noteStore.deleteNote(note)
                        currentIndex = 0
                    }
                )
                .id(note.id)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Text("🧠")
                        .font(.system(size: 48))
                    Text("All caught up!")
                        .font(.title2.bold())
                    Text("Your inbox is empty")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            noteStore.refresh()
            currentIndex = 0
        }
    }
}
