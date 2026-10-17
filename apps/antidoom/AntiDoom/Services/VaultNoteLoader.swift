import Foundation

/// Notas del vault (semilla JSON generada desde Daily Notes / Inbox en el Mac).
enum VaultNoteLoader {
    static func load(from bundle: Bundle = .main, limit: Int = 3) -> [RationItem] {
        guard let url = bundle.url(forResource: "seed_notes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([SeedNote].self, from: data)
        else {
            return []
        }
        return Array(rows.prefix(limit).map(\.asRationItem))
    }
}

private struct SeedNote: Codable {
    let title: String
    let summary: String
    let path: String?
    let publishedAt: String?

    var asRationItem: RationItem {
        let date: Date? = {
            guard let publishedAt else { return nil }
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: publishedAt)
        }()
        return RationItem(
            title: title,
            summary: summary,
            url: nil,
            sourceName: path.map { "Vault · \($0)" } ?? "Vault",
            kind: .note,
            publishedAt: date ?? Date()
        )
    }
}
