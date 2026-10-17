import Foundation

enum RationSourceKind: String, Codable, CaseIterable, Identifiable {
    case blog
    case news
    case podcast
    case tweet

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blog: "Blog"
        case .news: "Noticia"
        case .podcast: "Podcast"
        case .tweet: "Tweet"
        }
    }
}

struct RationItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let url: URL?
    let sourceName: String
    let kind: RationSourceKind
    let publishedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        url: URL? = nil,
        sourceName: String,
        kind: RationSourceKind,
        publishedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.url = url
        self.sourceName = sourceName
        self.kind = kind
        self.publishedAt = publishedAt
    }
}
