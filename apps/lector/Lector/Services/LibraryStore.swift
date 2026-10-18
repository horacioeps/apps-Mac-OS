import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var books: [BookItem] = []
    @Published var errorMessage: String?

    nonisolated static var booksDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Lector/Books", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var catalogURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lector/catalog.json")
    }

    init() {
        load()
        ensureSeedBook()
    }

    func load() {
        guard let data = try? Data(contentsOf: catalogURL),
              let decoded = try? JSONDecoder().decode([BookItem].self, from: data) else {
            books = []
            return
        }
        books = decoded.sorted { ($0.lastOpenedAt ?? $0.importedAt) > ($1.lastOpenedAt ?? $1.importedAt) }
    }

    private func persist() {
        let dir = catalogURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(books) {
            try? data.write(to: catalogURL, options: .atomic)
        }
    }

    func ensureSeedBook() {
        guard !books.contains(where: { $0.relativePath == "seed_book.md" }) else { return }
        guard let seed = Bundle.main.url(forResource: "seed_book", withExtension: "md") else { return }
        let dest = Self.booksDirectory.appendingPathComponent("seed_book.md")
        if !FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.copyItem(at: seed, to: dest)
        }
        let item = BookItem(
            id: UUID(),
            title: "Zoom de lectura (ejemplo)",
            author: "Lector",
            format: .markdown,
            relativePath: "seed_book.md",
            importedAt: Date(),
            lastOpenedAt: nil,
            sourceLabel: "Semilla"
        )
        books.insert(item, at: 0)
        persist()
    }

    @discardableResult
    func importFile(from url: URL, sourceLabel: String = "Archivos") throws -> BookItem {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let format = BookFormat.from(url: url)
        let name = uniqueFileName(for: url.lastPathComponent)
        let dest = Self.booksDirectory.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)

        let title = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
        let item = BookItem(
            id: UUID(),
            title: title,
            author: nil,
            format: format,
            relativePath: name,
            importedAt: Date(),
            lastOpenedAt: nil,
            sourceLabel: sourceLabel
        )
        books.insert(item, at: 0)
        persist()
        return item
    }

    func markOpened(_ book: BookItem) {
        guard let idx = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[idx].lastOpenedAt = Date()
        persist()
    }

    func delete(_ book: BookItem) {
        try? FileManager.default.removeItem(at: book.fileURL)
        books.removeAll { $0.id == book.id }
        persist()
    }

    private func uniqueFileName(for original: String) -> String {
        let base = original.replacingOccurrences(of: "/", with: "-")
        let dest = Self.booksDirectory.appendingPathComponent(base)
        if !FileManager.default.fileExists(atPath: dest.path) { return base }
        let stem = (base as NSString).deletingPathExtension
        let ext = (base as NSString).pathExtension
        return "\(stem)-\(UUID().uuidString.prefix(8)).\(ext)"
    }
}
