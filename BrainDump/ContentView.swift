import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(NoteStore.self) private var noteStore

    var body: some View {
        Group {
            switch appState.currentMode {
            case .capture:
                CaptureView()
            case .review:
                ReviewView()
            case .savedNotes:
                SavedNotesView()
            case .editNote(let note):
                NoteEditorView(note: note)
            case .tutorial:
                TutorialView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 360, minHeight: 300)
    }
}
