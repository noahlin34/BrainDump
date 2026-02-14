import Foundation

enum AppMode: Equatable {
    case capture
    case review
    case savedNotes
    case editNote(Note)
    case tutorial
    case settings
}

@Observable
class AppState {
    var currentMode: AppMode = .capture
    var isPanelVisible = false
}
