import Foundation

struct ReviewCard: Identifiable, Codable, Hashable {
    let id: UUID
    var bookID: UUID
    var zoomNodeID: UUID?
    var prompt: String
    var answer: String
    var easeFactor: Double
    var intervalDays: Double
    var repetitions: Int
    var dueAt: Date
    var lastReviewedAt: Date?

    var isDue: Bool { dueAt <= Date() }

    static func make(bookID: UUID, zoomNodeID: UUID?, prompt: String, answer: String) -> ReviewCard {
        ReviewCard(
            id: UUID(),
            bookID: bookID,
            zoomNodeID: zoomNodeID,
            prompt: prompt,
            answer: answer,
            easeFactor: 2.5,
            intervalDays: 0,
            repetitions: 0,
            dueAt: Date(),
            lastReviewedAt: nil
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
