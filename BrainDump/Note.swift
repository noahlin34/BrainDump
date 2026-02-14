import Foundation

struct Note: Identifiable, Hashable {
    let id: String
    var content: String
    let createdAt: Date
    let fileURL: URL

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }

    static func parseDate(from filename: String) -> Date? {
        let parts = filename.split(separator: "_")
        guard parts.count >= 2 else { return nil }
        let dateStr = "\(parts[0])_\(parts[1])"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.date(from: dateStr)
    }

    static func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateStr = formatter.string(from: Date())
        let shortUUID = UUID().uuidString.prefix(6).lowercased()
        return "\(dateStr)_\(shortUUID)"
    }
}
