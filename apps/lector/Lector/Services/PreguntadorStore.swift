import Foundation
import Combine

/// Preguntador: cajas Leitner + cola de sesión de MemorizaGuion
/// (`Personal/Charlas/TEDX Almería 2026/app/repeticion espaciada iOS`).
@MainActor
final class PreguntadorStore: ObservableObject {
    @Published private(set) var cards: [ReviewCard] = []
    @Published var statusMessage: String = ""

    private var storeURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lector/preguntador.json")
    }

    init() { load() }

    /// Prioridad: vencidas → fallos → caja baja (MemorizaGuion / CLI).
    func dueCards(for bookID: UUID) -> [ReviewCard] {
        cards
            .filter { $0.bookID == bookID && $0.isDue }
            .sorted {
                if $0.fallos != $1.fallos { return $0.fallos > $1.fallos }
                if $0.caja != $1.caja { return $0.caja < $1.caja }
                return $0.dueAt < $1.dueAt
            }
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
                    answer: node.summary,
                    hints: [String(node.summary.prefix(40)) + "…"],
                    detailLevel: min(2, node.depth)
                )
            )
        }
        cards.append(contentsOf: generated.prefix(40))
        persist()
        statusMessage = "+\(min(40, generated.count)) tarjetas extractivas"
    }

    /// Genera preguntas con LLM a varios niveles (escaleta TEDx).
    func seedWithLLM(book: BookItem, root: ZoomNode) async {
        guard await LLMClient.shared.isConfigured() else {
            seedFromZoom(book: book, root: root)
            statusMessage = "Sin LLM → seed extractivo"
            return
        }
        statusMessage = "Generando preguntas LLM…"
        let material = flattenForPrompt(root)
        do {
            let raw = try await LLMClient.shared.complete(
                system: """
                Eres el Preguntador de Lectura: repetición espaciada para interiorizar un libro
                (como Memoriza Guion / TEDx Almería: pistas progresivas y varios niveles).
                Devuelve SOLO JSON:
                {"cards":[{"prompt":"...","answer":"...","hints":["pista1","pista2"],"detailLevel":0}]}
                detailLevel: 0=esquema, 1=medio, 2=detalle fino.
                8-14 tarjetas. Español. Basadas solo en el material. Pistas progresivas cortas.
                """,
                user: """
                Libro: \(book.title)

                Material (zoom):
                \(material.prefix(18_000))
                """,
                temperature: 0.4,
                maxTokens: 2500
            )
            let parsed = parseLLMCards(raw, bookID: book.id)
            let existing = Set(cards.filter { $0.bookID == book.id }.map(\.prompt))
            let fresh = parsed.filter { !existing.contains($0.prompt) }
            if fresh.isEmpty {
                seedFromZoom(book: book, root: root)
                statusMessage = "LLM vacío → seed extractivo"
            } else {
                cards.append(contentsOf: fresh)
                persist()
                statusMessage = "+\(fresh.count) tarjetas (Leitner TEDx)"
            }
        } catch {
            seedFromZoom(book: book, root: root)
            statusMessage = "LLM falló → extractivo (\(error.localizedDescription))"
        }
    }

    /// Califica con cajas Leitner de MemorizaGuion (`Nucleo.calificar`).
    func grade(_ card: ReviewCard, _ grade: ReviewGrade, primera: Bool = true) {
        guard let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }
        var c = cards[idx]
        LeitnerScheduler.grade(&c, ok: grade == .good, primera: primera)
        cards[idx] = c
        persist()
    }

    private func flattenForPrompt(_ node: ZoomNode, indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        var s = "\(pad)- \(node.title): \(node.summary)\n"
        if node.hasVerbatim {
            s += "\(pad)  verbatim: \(node.verbatim.prefix(400))\n"
        }
        for child in node.children {
            s += flattenForPrompt(child, indent: indent + 1)
        }
        return s
    }

    private func parseLLMCards(_ raw: String, bookID: UUID) -> [ReviewCard] {
        let jsonString = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = obj["cards"] as? [[String: Any]] else { return [] }
        return arr.compactMap { item in
            guard let prompt = item["prompt"] as? String,
                  let answer = item["answer"] as? String,
                  !prompt.isEmpty, !answer.isEmpty else { return nil }
            let hints = item["hints"] as? [String] ?? []
            let level = item["detailLevel"] as? Int ?? 1
            return .make(
                bookID: bookID,
                zoomNodeID: nil,
                prompt: prompt,
                answer: answer,
                hints: hints,
                detailLevel: level
            )
        }
    }

    private func walk(_ node: ZoomNode, visit: (ZoomNode) -> Void) {
        visit(node)
        for child in node.children { walk(child, visit: visit) }
    }
}
