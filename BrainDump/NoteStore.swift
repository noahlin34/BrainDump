import Foundation

@Observable
class NoteStore {
    var inboxNotes: [Note] = []
    var savedNotes: [Note] = []

    private let fileManager = FileManager.default

    var baseURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BrainDump")
    }

    var inboxURL: URL { baseURL.appendingPathComponent("inbox") }
    var savedURL: URL { baseURL.appendingPathComponent("saved") }

    init() {
        ensureDirectories()
        refresh()
    }

    private func ensureDirectories() {
        try? fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: savedURL, withIntermediateDirectories: true)
    }

    func refresh() {
        inboxNotes = loadNotes(from: inboxURL)
        savedNotes = loadNotes(from: savedURL)
    }

    private func loadNotes(from directory: URL) -> [Note] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "md" }
            .compactMap { url -> Note? in
                let filename = url.deletingPathExtension().lastPathComponent
                guard let content = try? String(contentsOf: url, encoding: .utf8),
                      let date = Note.parseDate(from: filename) else { return nil }
                return Note(id: filename, content: content, createdAt: date, fileURL: url)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createNote(content: String) {
        let filename = Note.generateFilename()
        let fileURL = inboxURL.appendingPathComponent("\(filename).md")
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        refresh()
    }

    func saveNote(_ note: Note) {
        let destination = savedURL.appendingPathComponent(note.fileURL.lastPathComponent)
        try? fileManager.moveItem(at: note.fileURL, to: destination)
        refresh()
    }

    func deleteNote(_ note: Note) {
        try? fileManager.removeItem(at: note.fileURL)
        refresh()
    }

    func updateNote(_ note: Note, content: String) {
        try? content.write(to: note.fileURL, atomically: true, encoding: .utf8)
        refresh()
    }

    func deleteSavedNote(_ note: Note) {
        try? fileManager.removeItem(at: note.fileURL)
        refresh()
    }
}
