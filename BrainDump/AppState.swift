import Foundation

enum AppMode: Equatable {
    case capture
    case review
    case savedNotes
    case editNote(Note)
}

@Observable
class AppState {
    var currentMode: AppMode = .capture
    var isPanelVisible = false
}
