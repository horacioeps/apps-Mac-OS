import Foundation
import Combine

/// Repetición espaciada tipo SM-2 (estilo proyecto TEDx / CLI de estudio del vault).
@MainActor
final class PreguntadorStore: ObservableObject {
    @Published private(set) var cards: [ReviewCard] = []

    private var storeURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lector/preguntador.json")
    }

    init() { load() }

    var dueCards: [ReviewCard] {
        cards.filter(\.isDue).sorted { $0.dueAt < $1.dueAt }
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([ReviewCard].self, from: data) else {
            cards = []
            return
        }
        cards = decoded
    }

    private func persist() {
        let dir = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(cards) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    func seedFromZoom(book: BookItem, root: ZoomNode) {
        let existing = Set(cards.filter { $0.bookID == book.id }.map(\.prompt))
        var generated: [ReviewCard] = []
        walk(root) { node in
            guard node.depth >= 1, !node.summary.isEmpty else { return }
            let prompt = "¿De qué trata «\(node.title)» en \(book.title)?"
            guard !existing.contains(prompt) else { return }
            generated.append(
                .make(
                    bookID: book.id,
                    zoomNodeID: node.id,
                    prompt: prompt,
                    answer: node.summary
                )
            )
        }
        cards.append(contentsOf: generated.prefix(40))
        persist()
    }

    func grade(_ card: ReviewCard, _ grade: ReviewGrade) {
        guard let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }
        var c = cards[idx]
        let q = Double(grade.rawValue)
        // SM-2 simplificado
        if grade == .again {
            c.repetitions = 0
            c.intervalDays = 0
            c.dueAt = Date().addingTimeInterval(10 * 60)
        } else {
            c.repetitions += 1
            if c.repetitions == 1 {
                c.intervalDays = 1
            } else if c.repetitions == 2 {
                c.intervalDays = 3
            } else {
                c.intervalDays = max(1, c.intervalDays * c.easeFactor)
            }
            c.easeFactor = max(1.3, c.easeFactor + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02)))
            c.dueAt = Date().addingTimeInterval(c.intervalDays * 24 * 3600)
        }
        c.lastReviewedAt = Date()
        cards[idx] = c
        persist()
    }

    private func walk(_ node: ZoomNode, visit: (ZoomNode) -> Void) {
        visit(node)
        for child in node.children { walk(child, visit: visit) }
    }
}
