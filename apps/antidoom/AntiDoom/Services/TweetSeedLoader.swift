import Foundation

/// Tweets de la ración v1: JSON local en el bundle (sin API en vivo).
enum TweetSeedLoader {
    static func load(from bundle: Bundle = .main) -> [RationItem] {
        guard let url = bundle.url(forResource: "seed_tweets", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([SeedTweet].self, from: data)
        else {
            return Self.fallback
        }
        return rows.map(\.asRationItem)
    }

    private static let fallback: [RationItem] = [
        RationItem(
            title: "Sustituye esto por tus top tweets",
            summary: "Edita Resources/seed_tweets.json o conecta la API en v1.1.",
            url: URL(string: "https://x.com"),
            sourceName: "Tweets",
            kind: .tweet,
            publishedAt: Date()
        )
    ]
}

private struct SeedTweet: Codable {
    let title: String
    let summary: String
    let url: String?
    let author: String?

    var asRationItem: RationItem {
        RationItem(
            title: title,
            summary: summary,
            url: url.flatMap(URL.init(string:)),
            sourceName: author.map { "@\($0)" } ?? "Tweets",
            kind: .tweet,
            publishedAt: Date()
        )
    }
}
