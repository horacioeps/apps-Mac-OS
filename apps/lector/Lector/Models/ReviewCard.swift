import Foundation

/// Tarjeta del Preguntador. Programación = cajas Leitner de MemorizaGuion (TEDx Almería).
struct ReviewCard: Identifiable, Codable, Hashable {
    let id: UUID
    var bookID: UUID
    var zoomNodeID: UUID?
    var prompt: String
    var answer: String
    /// Pistas progresivas (estilo MemorizaGuion / CLI estudio).
    var hints: [String]
    /// Nivel de detalle: 0 esquema · 1 medio · 2 fino (escaleta TEDx).
    var detailLevel: Int

    /// Caja Leitner 0…4 (intervalos: 10 min, 4 h, 1 d, 3 d, 7 d).
    var caja: Int
    var dueAt: Date
    var aciertos: Int
    var fallos: Int
    var visto: Int
    var lastReviewedAt: Date?

    /// Compat SM-2 antiguo (se ignoran al calificar con Leitner).
    var easeFactor: Double
    var intervalDays: Double
    var repetitions: Int
    var lapses: Int

    var isDue: Bool { dueAt <= Date() }

    enum CodingKeys: String, CodingKey {
        case id, bookID, zoomNodeID, prompt, answer, hints, detailLevel
        case caja, dueAt, aciertos, fallos, visto, lastReviewedAt
        case easeFactor, intervalDays, repetitions, lapses
    }

    init(
        id: UUID,
        bookID: UUID,
        zoomNodeID: UUID?,
        prompt: String,
        answer: String,
        hints: [String],
        detailLevel: Int,
        caja: Int = 0,
        dueAt: Date = Date(),
        aciertos: Int = 0,
        fallos: Int = 0,
        visto: Int = 0,
        lastReviewedAt: Date? = nil,
        easeFactor: Double = 2.5,
        intervalDays: Double = 0,
        repetitions: Int = 0,
        lapses: Int = 0
    ) {
        self.id = id
        self.bookID = bookID
        self.zoomNodeID = zoomNodeID
        self.prompt = prompt
        self.answer = answer
        self.hints = hints
        self.detailLevel = detailLevel
        self.caja = caja
        self.dueAt = dueAt
        self.aciertos = aciertos
        self.fallos = fallos
        self.visto = visto
        self.lastReviewedAt = lastReviewedAt
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
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
        caja = try c.decodeIfPresent(Int.self, forKey: .caja) ?? 0
        dueAt = try c.decodeIfPresent(Date.self, forKey: .dueAt) ?? Date()
        aciertos = try c.decodeIfPresent(Int.self, forKey: .aciertos) ?? 0
        fallos = try c.decodeIfPresent(Int.self, forKey: .fallos)
            ?? c.decodeIfPresent(Int.self, forKey: .lapses) ?? 0
        visto = try c.decodeIfPresent(Int.self, forKey: .visto)
            ?? c.decodeIfPresent(Int.self, forKey: .repetitions) ?? 0
        lastReviewedAt = try c.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        easeFactor = try c.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        intervalDays = try c.decodeIfPresent(Double.self, forKey: .intervalDays) ?? 0
        repetitions = try c.decodeIfPresent(Int.self, forKey: .repetitions) ?? visto
        lapses = try c.decodeIfPresent(Int.self, forKey: .lapses) ?? fallos
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
            detailLevel: detailLevel
        )
    }
}

/// Botones de sesión (MemorizaGuion: Reintentar / OK).
enum ReviewGrade: Int, CaseIterable, Identifiable {
    case again = 0
    case good = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: "↻ Reintentar"
        case .good: "✓ OK"
        }
    }
}

/// Intervalos por caja — copia de `Nucleo.intervalos` en MemorizaGuion (TEDx).
enum LeitnerScheduler {
    static let intervalos: [TimeInterval] = [
        10 * 60,
        4 * 3600,
        24 * 3600,
        3 * 24 * 3600,
        7 * 24 * 3600
    ]

    /// Equivalente a `Nucleo.calificar` (ok + primera respuesta de la sesión).
    static func grade(_ card: inout ReviewCard, ok: Bool, primera: Bool, ahora: Date = Date()) {
        let t = ahora.timeIntervalSince1970
        let tocaba = card.visto == 0 || !(card.dueAt.timeIntervalSince1970 > t)
        card.visto += 1
        card.lastReviewedAt = ahora
        if !ok {
            card.caja = 0
            card.fallos += 1
            card.lapses = card.fallos
            card.dueAt = ahora.addingTimeInterval(intervalos[0])
            card.repetitions = 0
            card.intervalDays = intervalos[0] / 86_400
        } else {
            card.aciertos += 1
            if primera && tocaba {
                card.caja = min(card.caja + 1, intervalos.count - 1)
                card.dueAt = ahora.addingTimeInterval(intervalos[card.caja])
                card.intervalDays = intervalos[card.caja] / 86_400
            }
            card.repetitions = card.caja
        }
    }
}

/// Cola intensiva de sesión — simplificación de `Cola` en MemorizaGuion.
final class ReviewSessionQueue {
    struct Entry {
        var card: ReviewCard
        var racha = 0
        var fallo = false
        var vista = false
    }

    private(set) var q: [Entry]
    /// Tras fallo: reinsertar a N posiciones (Normal = 3).
    private let falloHueco = 3
    /// Tras OK con fallo previo: reinsertar a estas posiciones y salir al superar.
    private let okHuecos = [8, 20]

    init(cards: [ReviewCard]) {
        q = cards.map { Entry(card: $0) }
    }

    var current: ReviewCard? { q.first?.card }
    var quedan: Int { q.count }

    private func meter(_ e: Entry, _ hueco: Int) {
        q.insert(e, at: min(max(hueco - 1, 1), q.count))
    }

    /// Devuelve `primera` para mover la caja persistente solo en la 1ª respuesta de sesión.
    func responder(ok: Bool) -> (primera: Bool, card: ReviewCard)? {
        guard !q.isEmpty else { return nil }
        var e = q.removeFirst()
        let primera = !e.vista
        e.vista = true
        if !ok {
            e.racha = 0
            e.fallo = true
            meter(e, falloHueco)
        } else {
            e.racha += 1
            let sale = !e.fallo || e.racha > okHuecos.count
            if !sale {
                meter(e, okHuecos[e.racha - 1])
            }
        }
        return (primera, e.card)
    }
}
