import Foundation

/// Chat anclado al nodo de zoom. Prefiere LLM; fallback extractivo local.
@MainActor
final class ChatService: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var isThinking = false
    @Published var lastMode: String = ""

    func reset(for bookTitle: String, node: ZoomNode) {
        let llm = LLMSettings.hasKey && LLMSettings.useLLM
        messages = [
            ChatMessage(
                role: .system,
                text: "Contexto: «\(bookTitle)» → \(node.title)",
                zoomNodeID: node.id
            ),
            ChatMessage(
                role: .assistant,
                text: llm
                    ? "Pregúntame sobre este nivel del zoom. Responderé con el modelo \(LLMSettings.model) usando el texto de «\(node.title)»."
                    : "Modo local (sin API key). Puedes preguntar; las respuestas serán extractivas. Activa OpenAI en Ajustes para chat LLM.",
                zoomNodeID: node.id
            )
        ]
        lastMode = ""
    }

    func ask(_ question: String, bookTitle: String, node: ZoomNode) async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: q, zoomNodeID: node.id))
        isThinking = true
        defer { isThinking = false }

        let context = [node.summary, node.verbatim]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        if await LLMClient.shared.isConfigured() {
            do {
                let reply = try await llmAnswer(question: q, context: context, nodeTitle: node.title, bookTitle: bookTitle)
                lastMode = "LLM · \(LLMSettings.model)"
                messages.append(ChatMessage(role: .assistant, text: reply, zoomNodeID: node.id))
                return
            } catch {
                lastMode = "local (LLM falló)"
                let fallback = localAnswer(question: q, context: context, nodeTitle: node.title, bookTitle: bookTitle)
                messages.append(ChatMessage(
                    role: .assistant,
                    text: "\(fallback)\n\n— Nota: \(error.localizedDescription)",
                    zoomNodeID: node.id
                ))
                return
            }
        }

        lastMode = "local"
        let reply = localAnswer(question: q, context: context, nodeTitle: node.title, bookTitle: bookTitle)
        messages.append(ChatMessage(role: .assistant, text: reply, zoomNodeID: node.id))
    }

    private func llmAnswer(question: String, context: String, nodeTitle: String, bookTitle: String) async throws -> String {
        let system = """
        Eres el asistente de lectura de la app Lector (iPad).
        Responde en español, breve y fiel al contexto del nodo de zoom actual.
        Si el contexto no basta, dilo; no inventes citas.
        Nodo: «\(nodeTitle)» del libro «\(bookTitle)».
        """
        let user = """
        Contexto del nodo:
        ---
        \(context.prefix(12_000))
        ---

        Pregunta: \(question)
        """
        var history: [[String: String]] = [["role": "system", "content": system]]
        for msg in messages where msg.role != .system {
            history.append([
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.text
            ])
        }
        // La última user ya está en messages; evitamos duplicar si ask la añadió antes
        if history.last?["role"] != "user" {
            history.append(["role": "user", "content": user])
        } else {
            // Sustituye el último user por versión con contexto embebido
            history[history.count - 1] = ["role": "user", "content": user]
        }
        return try await LLMClient.shared.complete(messages: history, temperature: 0.35)
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
            return "En «\(nodeTitle)» (\(bookTitle)): \(fallback)."
        }
        return "Según «\(nodeTitle)»: " + picks.map { "• \($0)." }.joined(separator: "\n")
    }
}
