import Foundation

/// Construye el árbol de zoom a partir del texto / capítulos del libro.
enum ZoomTreeService {
    /// Árbol desde capítulos EPUB (spine/TOC). Evita 87× «§ N» sobre un blob plano.
    static func buildTree(title: String, chapters: [ReadiumBridge.Chapter]) -> ZoomNode {
        let usable = chapters.filter { !isBoilerplateTitle($0.title) || $0.body.count > 800 }
        let list = usable.isEmpty ? chapters : usable

        var offset = 0
        var children: [ZoomNode] = []
        for chapter in list {
            let start = offset
            let end = start + chapter.body.count
            let chunks = mergedChunks(of: chapter.body, depth: 2, baseOffset: start, maxChunks: 10)
            children.append(
                ZoomNode(
                    id: UUID(),
                    title: chapter.title,
                    summary: summarize(chapter.body, maxSentences: 2, maxChars: 280),
                    verbatim: "",
                    children: chunks,
                    sourceStart: start,
                    sourceEnd: end,
                    depth: 1
                )
            )
            offset = end + 2
        }

        let outline = list.prefix(14).map(\.title).joined(separator: " · ")
        let rootSummary = summarize(
            list.drop(while: { isBoilerplateTitle($0.title) }).first?.body
                ?? list.first?.body
                ?? "",
            maxSentences: 3,
            maxChars: 320
        )
        let summary = rootSummary.isEmpty
            ? "\(list.count) secciones: \(outline)"
            : "\(rootSummary)\n\n(\(list.count) secciones)"

        return ZoomNode(
            id: UUID(),
            title: title,
            summary: summary,
            verbatim: "",
            children: children,
            sourceStart: 0,
            sourceEnd: offset,
            depth: 0
        )
    }

    static func buildTree(title: String, fullText: String) -> ZoomNode {
        let sections = splitIntoSections(fullText)
        if sections.isEmpty {
            let chunks = mergedChunks(of: fullText, depth: 1, baseOffset: 0, maxChunks: 24)
            return ZoomNode(
                id: UUID(),
                title: title,
                summary: summarize(fullText, maxSentences: 3, maxChars: 320),
                verbatim: "",
                children: chunks,
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
            children.append(
                ZoomNode(
                    id: UUID(),
                    title: section.title,
                    summary: summarize(section.body, maxSentences: 2, maxChars: 280),
                    verbatim: "",
                    children: mergedChunks(of: section.body, depth: 2, baseOffset: start, maxChunks: 10),
                    sourceStart: start,
                    sourceEnd: end,
                    depth: 1
                )
            )
            cursor = range.upperBound
        }

        return ZoomNode(
            id: UUID(),
            title: title,
            summary: summarize(fullText, maxSentences: 3, maxChars: 320),
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

    /// Mejora resúmenes del árbol con LLM (raíz + hijos de profundidad 1).
    static func enrichWithLLM(root: ZoomNode, fullText: String) async -> (ZoomNode, String) {
        guard await LLMClient.shared.isConfigured() else {
            return (root, "extractivo")
        }
        // No bombardear con 80 capítulos: solo los primeros títulos.
        let chapterTitles = root.children.prefix(40).map(\.title)
        do {
            let outline = try await LLMClient.shared.complete(
                system: """
                Generas resúmenes para zoom de lectura multinivel (visión general → detalle).
                Responde SOLO JSON válido UTF-8, sin markdown:
                {"rootSummary":"...","chapters":[{"title":"...","summary":"..."}]}
                rootSummary: 2-4 frases del libro entero.
                chapters: un ítem por cada título hijo de primer nivel (mismos títulos exactos).
                Español. Fiel al texto. Sin inventar secciones.
                """,
                user: """
                Título: \(root.title)

                Hijos (títulos exactos):
                \(chapterTitles.joined(separator: "\n"))

                Texto (recortado):
                \(fullText.prefix(24_000))
                """,
                temperature: 0.25,
                maxTokens: 2200
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
            next.summary = String(rootSummary.prefix(500))
        }
        guard let chapters = obj["chapters"] as? [[String: Any]] else { return next }
        let byTitle = Dictionary(uniqueKeysWithValues: chapters.compactMap { item -> (String, String)? in
            guard let t = item["title"] as? String, let s = item["summary"] as? String else { return nil }
            return (t.lowercased(), s)
        })
        next.children = next.children.map { child in
            var c = child
            if let s = byTitle[child.title.lowercased()], !s.isEmpty {
                c.summary = String(s.prefix(400))
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

    private static func isBoilerplateTitle(_ title: String) -> Bool {
        let t = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let junk = [
            "contents", "table of contents", "copyright", "title page", "titlepage",
            "epigraph", "dedication", "also by", "about the author", "praise",
            "cover", "halftitle", "copyright page"
        ]
        return junk.contains(where: { t == $0 || t.hasPrefix($0) })
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
        if trimmed.range(of: #"^(Cap[ií]tulo|CHAPTER|Chapter|Part|Parte)\b"#, options: .regularExpression) != nil {
            return trimmed
        }
        return nil
    }

    /// Agrupa párrafos en pocos bloques legibles (no un nodo por párrafo).
    private static func mergedChunks(
        of text: String,
        depth: Int,
        baseOffset: Int,
        maxChunks: Int,
        targetChars: Int = 1_400
    ) -> [ZoomNode] {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if paragraphs.isEmpty {
            let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { return [] }
            return [
                ZoomNode(
                    id: UUID(),
                    title: "Texto",
                    summary: summarize(body, maxSentences: 1, maxChars: 160),
                    verbatim: body,
                    children: [],
                    sourceStart: baseOffset,
                    sourceEnd: baseOffset + body.count,
                    depth: depth
                )
            ]
        }

        var bundles: [(title: String, body: String)] = []
        var current = ""
        var part = 1
        for para in paragraphs {
            if current.isEmpty {
                current = para
            } else if current.count + para.count + 2 <= targetChars {
                current += "\n\n" + para
            } else {
                bundles.append(("§ \(part)", current))
                part += 1
                current = para
            }
        }
        if !current.isEmpty {
            bundles.append(("§ \(part)", current))
        }

        // Si aún hay demasiados, fusionar contiguos
        while bundles.count > maxChunks {
            var merged: [(String, String)] = []
            var i = 0
            var n = 1
            while i < bundles.count {
                if i + 1 < bundles.count, merged.count + (bundles.count - i) / 2 >= maxChunks - 1 || bundles.count > maxChunks {
                    let a = bundles[i].body
                    let b = bundles[i + 1].body
                    merged.append(("§ \(n)", a + "\n\n" + b))
                    i += 2
                } else {
                    merged.append(("§ \(n)", bundles[i].body))
                    i += 1
                }
                n += 1
            }
            bundles = merged.map { ($0.0, $0.1) }
            if bundles.count > maxChunks {
                // Forzar: trocear por tamaño igual
                let joined = bundles.map(\.1).joined(separator: "\n\n")
                let size = max(targetChars, joined.count / maxChunks + 1)
                bundles = []
                var start = joined.startIndex
                var idx = 1
                while start < joined.endIndex {
                    let end = joined.index(start, offsetBy: size, limitedBy: joined.endIndex) ?? joined.endIndex
                    bundles.append(("§ \(idx)", String(joined[start..<end])))
                    start = end
                    idx += 1
                    if bundles.count >= maxChunks {
                        if start < joined.endIndex {
                            let last = bundles.removeLast()
                            bundles.append((last.0, last.1 + String(joined[start...])))
                        }
                        break
                    }
                }
                break
            }
        }

        var searchFrom = text.startIndex
        return bundles.enumerated().map { idx, bundle in
            let range = text.range(of: bundle.body, range: searchFrom..<text.endIndex)
                ?? text.range(of: String(bundle.body.prefix(80)))
            let start: Int
            if let range {
                start = baseOffset + text.distance(from: text.startIndex, to: range.lowerBound)
                searchFrom = range.upperBound
            } else {
                start = baseOffset
            }
            return ZoomNode(
                id: UUID(),
                title: bundle.title,
                summary: summarize(bundle.body, maxSentences: 1, maxChars: 160),
                verbatim: bundle.body,
                children: [],
                sourceStart: start,
                sourceEnd: start + bundle.body.count,
                depth: depth
            )
        }
    }

    private static func summarize(_ text: String, maxSentences: Int, maxChars: Int = 280) -> String {
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
        let joined: String
        if sentences.isEmpty {
            joined = String(cleaned.prefix(maxChars))
        } else {
            joined = sentences.prefix(maxSentences).joined(separator: " ")
        }
        if joined.count <= maxChars { return joined }
        return String(joined.prefix(maxChars - 1)) + "…"
    }
}
