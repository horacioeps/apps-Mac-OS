import Foundation

enum BookFormat: String, Codable, CaseIterable, Identifiable {
    case pdf
    case epub
    case markdown
    case plainText
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pdf: "PDF"
        case .epub: "EPUB"
        case .markdown: "Markdown"
        case .plainText: "Texto"
        case .unknown: "Otro"
        }
    }

    static func from(url: URL) -> BookFormat {
        switch url.pathExtension.lowercased() {
        case "pdf": .pdf
        case "epub": .epub
        case "md", "markdown": .markdown
        case "txt": .plainText
        default: .unknown
        }
    }
}

struct BookItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var author: String?
    var format: BookFormat
    /// Relative path under Application Support/Books/
    var relativePath: String
    var importedAt: Date
    var lastOpenedAt: Date?
    var sourceLabel: String

    var fileURL: URL {
        LibraryStore.booksDirectory.appendingPathComponent(relativePath)
    }
}
