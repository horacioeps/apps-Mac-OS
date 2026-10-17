import Foundation
import SwiftUI

@MainActor
final class RationStore: ObservableObject {
    @Published private(set) var items: [RationItem] = []
    @Published private(set) var consumedIDs: Set<UUID> = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published var rationSize: Int {
        didSet { UserDefaults.standard.set(rationSize, forKey: Keys.rationSize) }
    }

    @Published var feeds: [FeedSource] {
        didSet { persistFeeds() }
    }

    private let rss = RSSClient()
    private let calendar = Calendar.current

    private enum Keys {
        static let rationSize = "antidoom.rationSize"
        static let feeds = "antidoom.feeds"
        static let consumed = "antidoom.consumed"
        static let day = "antidoom.day"
    }

    init() {
        let storedSize = UserDefaults.standard.integer(forKey: Keys.rationSize)
        rationSize = storedSize > 0 ? storedSize : 7
        feeds = Self.loadFeeds()
        resetDayIfNeeded()
        restoreConsumed()
    }

    var remaining: [RationItem] {
        items.filter { !consumedIDs.contains($0.id) }
    }

    var current: RationItem? { remaining.first }

    var consumedCount: Int { consumedIDs.count }

    var totalCount: Int { items.count }

    var isFinished: Bool { !items.isEmpty && remaining.isEmpty }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        var collected: [RationItem] = []
        let enabled = feeds.filter(\.enabled)
        let client = rss

        await withTaskGroup(of: [RationItem].self) { group in
            for feed in enabled {
                group.addTask {
                    do {
                        return try await client.fetchItems(from: feed, limit: 5)
                    } catch {
                        return []
                    }
                }
            }
            for await batch in group {
                collected.append(contentsOf: batch)
            }
        }

        collected.append(contentsOf: TweetSeedLoader.load())

        // Vault: asegurar 1–2 trozos en la ración (no solo por fecha).
        let vaultNotes = VaultNoteLoader.load(limit: 3)
        let vaultSlots = min(2, vaultNotes.count)

        collected.sort { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
        let unique = Self.dedupe(collected)

        var ration: [RationItem] = Array(vaultNotes.prefix(vaultSlots))
        for item in unique where ration.count < rationSize {
            let key = (item.url?.absoluteString ?? item.title).lowercased()
            let already = ration.contains {
                ($0.url?.absoluteString ?? $0.title).lowercased() == key
            }
            if !already {
                ration.append(item)
            }
        }
        items = ration

        if items.isEmpty {
            lastError = "No hay ítems. Revisa feeds o la red."
        }

        // Nueva ración: no arrastrar consumidos de un refresh manual del mismo día.
        consumedIDs = consumedIDs.intersection(Set(items.map(\.id)))
        persistConsumed()
    }

    func markConsumed(_ item: RationItem) {
        consumedIDs.insert(item.id)
        persistConsumed()
    }

    func resetRationForToday() {
        consumedIDs.removeAll()
        persistConsumed()
    }

    private func resetDayIfNeeded() {
        let today = calendar.startOfDay(for: Date()).timeIntervalSince1970
        let stored = UserDefaults.standard.double(forKey: Keys.day)
        if stored != today {
            UserDefaults.standard.set(today, forKey: Keys.day)
            consumedIDs.removeAll()
            UserDefaults.standard.removeObject(forKey: Keys.consumed)
        }
    }

    private func restoreConsumed() {
        guard let data = UserDefaults.standard.data(forKey: Keys.consumed),
              let ids = try? JSONDecoder().decode([UUID].self, from: data)
        else { return }
        consumedIDs = Set(ids)
    }

    private func persistConsumed() {
        let data = try? JSONEncoder().encode(Array(consumedIDs))
        UserDefaults.standard.set(data, forKey: Keys.consumed)
    }

    private func persistFeeds() {
        guard let data = try? JSONEncoder().encode(feeds) else { return }
        UserDefaults.standard.set(data, forKey: Keys.feeds)
    }

    private static func loadFeeds() -> [FeedSource] {
        if let data = UserDefaults.standard.data(forKey: Keys.feeds),
           let decoded = try? JSONDecoder().decode([FeedSource].self, from: data),
           !decoded.isEmpty
        {
            return decoded
        }
        return DefaultFeeds.all
    }

    private static func dedupe(_ items: [RationItem]) -> [RationItem] {
        var seen = Set<String>()
        var out: [RationItem] = []
        for item in items {
            let key = (item.url?.absoluteString ?? item.title).lowercased()
            if seen.insert(key).inserted {
                out.append(item)
            }
        }
        return out
    }
}
