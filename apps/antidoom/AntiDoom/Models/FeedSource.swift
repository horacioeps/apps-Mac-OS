import Foundation

struct FeedSource: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var feedURL: URL
    var kind: RationSourceKind
    var enabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        feedURL: URL,
        kind: RationSourceKind,
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.feedURL = feedURL
        self.kind = kind
        self.enabled = enabled
    }
}

enum DefaultFeeds {
    /// Feeds de ejemplo para arrancar la v1. Sustituye por los tuyos en Ajustes.
    static let all: [FeedSource] = [
        FeedSource(
            name: "Emilcar Daily",
            feedURL: URL(string: "https://feeds.feedburner.com/emilcar")!,
            kind: .podcast
        ),
        FeedSource(
            name: "Hacker News",
            feedURL: URL(string: "https://hnrss.org/frontpage")!,
            kind: .news
        ),
        FeedSource(
            name: "Swift.org Blog",
            feedURL: URL(string: "https://www.swift.org/atom.xml")!,
            kind: .blog
        ),
    ]
}
