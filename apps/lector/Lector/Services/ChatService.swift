import Foundation

/// Chat anclado al nodo de zoom actual. v0: respuesta local extractiva; hook LLM después.
@MainActor
final class ChatService: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var isThinking = false

    func reset(for bookTitle: String, node: ZoomNode) {
        messages = [
            ChatMessage(
                role: .system,
                text: "Contexto: «\(bookTitle)» → \(node.title)",
                zoomNodeID: node.id
            ),
            ChatMessage(
                role: .assistant,
                text: "Puedes preguntarme sobre este nivel del zoom. Uso el resumen y el texto asociado a «\(node.title)».",
                zoomNodeID: node.id
            )
        ]
    }

    func ask(_ question: String, bookTitle: String, node: ZoomNode) async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: q, zoomNodeID: node.id))
        isThinking = true
        defer { isThinking = false }

        try? await Task.sleep(nanoseconds: 250_000_000)
        let context = [node.summary, node.verbatim]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        let reply = localAnswer(question: q, context: context, nodeTitle: node.title, bookTitle: bookTitle)
        messages.append(ChatMessage(role: .assistant, text: reply, zoomNodeID: node.id))
    }

    private func localAnswer(question: String, context: String, nodeTitle: String, bookTitle: String) -> String {
        if context.isEmpty {
            return "Este nodo aún no tiene texto. Baja un nivel en el zoom o importa un libro con texto extraíble."
        }
        let needles = question
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
        let sentences = context
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let ranked = sentences
            .map { s -> (String, Int) in
                let score = needles.reduce(0) { acc, w in
                    acc + (s.lowercased().contains(w) ? 1 : 0)
                }
                return (s, score)
            }
            .sorted { $0.1 > $1.1 }

        let picks = ranked.filter { $0.1 > 0 }.prefix(3).map(\.0)
        if picks.isEmpty {
            let fallback = sentences.prefix(2).joined(separator: ". ")
            return """
            En «\(nodeTitle)» (\(bookTitle)) lo más cercano que tengo es:

            \(fallback).

            (Chat local v0 — sin LLM. Conectaremos API después.)
            """
        }
        return """
        Según el nodo «\(nodeTitle)»:

        \(picks.map { "• \($0)." }.joined(separator: "\n"))

        (Chat local v0 — sin LLM.)
        """
    }
}
