import Foundation

struct ReviewCard: Identifiable, Codable, Hashable {
    let id: UUID
    var bookID: UUID
    var zoomNodeID: UUID?
    var prompt: String
    var answer: String
    /// Pistas progresivas (estilo CLI estudio / TEDx repaso).
    var hints: [String]
    /// Nivel de detalle: 0 esquema · 1 medio · 2 fino (escaleta TEDx).
    var detailLevel: Int
    var easeFactor: Double
    var intervalDays: Double
    var repetitions: Int
    var dueAt: Date
    var lastReviewedAt: Date?
    var lapses: Int

    var isDue: Bool { dueAt <= Date() }

    enum CodingKeys: String, CodingKey {
        case id, bookID, zoomNodeID, prompt, answer, hints, detailLevel
        case easeFactor, intervalDays, repetitions, dueAt, lastReviewedAt, lapses
    }

    init(
        id: UUID,
        bookID: UUID,
        zoomNodeID: UUID?,
        prompt: String,
        answer: String,
        hints: [String],
        detailLevel: Int,
        easeFactor: Double,
        intervalDays: Double,
        repetitions: Int,
        dueAt: Date,
        lastReviewedAt: Date?,
        lapses: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.zoomNodeID = zoomNodeID
        self.prompt = prompt
        self.answer = answer
        self.hints = hints
        self.detailLevel = detailLevel
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.dueAt = dueAt
        self.lastReviewedAt = lastReviewedAt
        self.lapses = lapses
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        bookID = try c.decode(UUID.self, forKey: .bookID)
        zoomNodeID = try c.decodeIfPresent(UUID.self, forKey: .zoomNodeID)
        prompt = try c.decode(String.self, forKey: .prompt)
        answer = try c.decode(String.self, forKey: .answer)
        hints = try c.decodeIfPresent([String].self, forKey: .hints) ?? []
        detailLevel = try c.decodeIfPresent(Int.self, forKey: .detailLevel) ?? 1
        easeFactor = try c.decode(Double.self, forKey: .easeFactor)
        intervalDays = try c.decode(Double.self, forKey: .intervalDays)
        repetitions = try c.decode(Int.self, forKey: .repetitions)
        dueAt = try c.decode(Date.self, forKey: .dueAt)
        lastReviewedAt = try c.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        lapses = try c.decodeIfPresent(Int.self, forKey: .lapses) ?? 0
    }

    static func make(
        bookID: UUID,
        zoomNodeID: UUID?,
        prompt: String,
        answer: String,
        hints: [String] = [],
        detailLevel: Int = 1
    ) -> ReviewCard {
        ReviewCard(
            id: UUID(),
            bookID: bookID,
            zoomNodeID: zoomNodeID,
            prompt: prompt,
            answer: answer,
            hints: hints,
            detailLevel: detailLevel,
            easeFactor: 2.5,
            intervalDays: 0,
            repetitions: 0,
            dueAt: Date(),
            lastReviewedAt: nil,
            lapses: 0
        )
    }
}

enum ReviewGrade: Int, CaseIterable, Identifiable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: "Otra vez"
        case .hard: "Difícil"
        case .good: "Bien"
        case .easy: "Fácil"
        }
    }
}
