import Foundation
import Combine

struct Highlight: Identifiable, Codable, Hashable {
    let id: UUID
    var bookID: UUID
    var text: String
    var note: String
    var zoomNodeID: UUID?
    var createdAt: Date
}

/// Readwise propio: highlights locales + export Markdown.
@MainActor
final class HighlightStore: ObservableObject {
    @Published private(set) var highlights: [Highlight] = []

    private var storeURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lector/highlights.json")
    }

    init() { load() }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([Highlight].self, from: data) else {
            highlights = []
            return
        }
        highlights = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() {
        let dir = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(highlights) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    func add(bookID: UUID, text: String, note: String = "", zoomNodeID: UUID?) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        highlights.insert(
            Highlight(id: UUID(), bookID: bookID, text: t, note: note, zoomNodeID: zoomNodeID, createdAt: Date()),
            at: 0
        )
        persist()
    }

    func delete(_ h: Highlight) {
        highlights.removeAll { $0.id == h.id }
        persist()
    }

    func markdownExport(bookTitle: String, bookID: UUID) -> String {
        let items = highlights.filter { $0.bookID == bookID }
        var md = "# Highlights — \(bookTitle)\n\n"
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        for h in items {
            md += "> \(h.text)\n\n"
            if !h.note.isEmpty { md += "\(h.note)\n\n" }
            md += "_\(fmt.string(from: h.createdAt))_\n\n---\n\n"
        }
        return md
    }
}
