import Foundation

/// Construye el árbol de zoom a partir del texto del libro (extractivo local).
/// Más adelante: nodos generados por LLM según la nota del vault.
enum ZoomTreeService {
    static func buildTree(title: String, fullText: String) -> ZoomNode {
        let sections = splitIntoSections(fullText)
        if sections.isEmpty {
            return ZoomNode(
                id: UUID(),
                title: title,
                summary: summarize(fullText, maxSentences: 3),
                verbatim: fullText,
                children: leafChunks(of: fullText, depth: 1),
                sourceStart: 0,
                sourceEnd: fullText.count,
                depth: 0
            )
        }

        var cursor = fullText.startIndex
        var children: [ZoomNode] = []
        for section in sections {
            let range = fullText.range(of: section.body) ?? (cursor..<cursor)
            let start = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
            let end = fullText.distance(from: fullText.startIndex, to: range.upperBound)
            let node = ZoomNode(
                id: UUID(),
                title: section.title,
                summary: summarize(section.body, maxSentences: 2),
                verbatim: "",
                children: leafChunks(of: section.body, depth: 2, baseOffset: start),
                sourceStart: start,
                sourceEnd: end,
                depth: 1
            )
            children.append(node)
            cursor = range.upperBound
        }

        return ZoomNode(
            id: UUID(),
            title: title,
            summary: summarize(fullText, maxSentences: 4),
            verbatim: "",
            children: children,
            sourceStart: 0,
            sourceEnd: fullText.count,
            depth: 0
        )
    }

    static func node(at path: ZoomPath, in root: ZoomNode) -> ZoomNode {
        var current = root
        for id in path.nodeIDs {
            guard let next = current.children.first(where: { $0.id == id }) else { return current }
            current = next
        }
        return current
    }

    /// Mejora resúmenes del árbol con LLM (raíz + hijos de profundidad 1). Fallback: árbol extractivo.
    static func enrichWithLLM(root: ZoomNode, fullText: String) async -> (ZoomNode, String) {
        guard await LLMClient.shared.isConfigured() else {
            return (root, "extractivo")
        }
        do {
            let outline = try await LLMClient.shared.complete(
                system: """
                Generas resúmenes para zoom de lectura multinivel (visión general → detalle).
                Responde SOLO JSON válido UTF-8, sin markdown:
                {"rootSummary":"...","chapters":[{"title":"...","summary":"..."}]}
                rootSummary: 2-4 frases del libro entero.
                chapters: un ítem por cada título hijo de primer nivel (mismos títulos).
                Español. Fiel al texto. Sin inventar secciones.
                """,
                user: """
                Título: \(root.title)

                Hijos (títulos exactos):
                \(root.children.map(\.title).joined(separator: "\n"))

                Texto (recortado):
                \(fullText.prefix(24_000))
                """,
                temperature: 0.25,
                maxTokens: 1800
            )
            let enriched = applyLLMOutline(outline, to: root)
            return (enriched, "LLM · \(LLMSettings.model)")
        } catch {
            return (root, "extractivo (\(error.localizedDescription))")
        }
    }

    private static func applyLLMOutline(_ raw: String, to root: ZoomNode) -> ZoomNode {
        let jsonString = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return root
        }
        var next = root
        if let rootSummary = obj["rootSummary"] as? String, !rootSummary.isEmpty {
            next.summary = rootSummary
        }
        guard let chapters = obj["chapters"] as? [[String: Any]] else { return next }
        let byTitle = Dictionary(uniqueKeysWithValues: chapters.compactMap { item -> (String, String)? in
            guard let t = item["title"] as? String, let s = item["summary"] as? String else { return nil }
            return (t.lowercased(), s)
        })
        next.children = next.children.map { child in
            var c = child
            if let s = byTitle[child.title.lowercased()], !s.isEmpty {
                c.summary = s
            }
            return c
        }
        return next
    }

    // MARK: - private

    private struct Section {
        var title: String
        var body: String
    }

    private static func splitIntoSections(_ text: String) -> [Section] {
        let lines = text.components(separatedBy: "\n")
        var sections: [Section] = []
        var currentTitle: String?
        var bodyLines: [String] = []

        func flush() {
            guard let title = currentTitle else { return }
            let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                sections.append(Section(title: title, body: body))
            }
            bodyLines = []
        }

        for line in lines {
            if let heading = headingTitle(line) {
                flush()
                currentTitle = heading
            } else if currentTitle != nil {
                bodyLines.append(line)
            }
        }
        flush()
        return sections
    }

    private static func headingTitle(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            return String(trimmed.drop(while: { $0 == "#" || $0 == " " }))
        }
        // Capítulos tipo "Capítulo 1" / "CHAPTER 1"
        if trimmed.range(of: #"^(Cap[ií]tulo|CHAPTER|Chapter)\b"#, options: .regularExpression) != nil {
            return trimmed
        }
        return nil
    }

    private static func leafChunks(of text: String, depth: Int, baseOffset: Int = 0) -> [ZoomNode] {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if paragraphs.count <= 1 {
            return [
                ZoomNode(
                    id: UUID(),
                    title: "Texto",
                    summary: summarize(text, maxSentences: 1),
                    verbatim: text,
                    children: [],
                    sourceStart: baseOffset,
                    sourceEnd: baseOffset + text.count,
                    depth: depth
                )
            ]
        }

        var offset = 0
        return paragraphs.enumerated().map { idx, para in
            let localStart = text.range(of: para)?.lowerBound
            let start: Int
            if let localStart {
                start = baseOffset + text.distance(from: text.startIndex, to: localStart)
            } else {
                start = baseOffset + offset
            }
            let end = start + para.count
            offset = end
            return ZoomNode(
                id: UUID(),
                title: "§ \(idx + 1)",
                summary: summarize(para, maxSentences: 1),
                verbatim: para,
                children: [],
                sourceStart: start,
                sourceEnd: end,
                depth: depth
            )
        }
    }

    private static func summarize(_ text: String, maxSentences: Int) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "(sin resumen)" }

        var sentences: [String] = []
        cleaned.enumerateSubstrings(in: cleaned.startIndex..., options: [.bySentences, .localized]) { sub, _, _, _ in
            if let sub {
                let t = sub.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { sentences.append(t) }
            }
        }
        if sentences.isEmpty { return String(cleaned.prefix(220)) }
        return sentences.prefix(maxSentences).joined(separator: " ")
    }
}
