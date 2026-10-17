import Foundation

/// Procesa texto crudo del feed en un trozo corto tipo resumen (extractivo, on-device).
enum SummaryProcessor {
    static func summarize(_ raw: String, kind: RationSourceKind, maxChars: Int = 420) -> String {
        let plain = stripHTML(raw)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !plain.isEmpty else { return "" }

        let core: String
        if kind == .news {
            core = extractiveNewsSummary(plain, maxChars: maxChars)
        } else {
            core = truncateAtWord(plain, maxChars: maxChars)
        }

        guard !core.isEmpty else { return "" }
        if kind == .news {
            return "Resumen: \(core)"
        }
        return core
    }

    private static func extractiveNewsSummary(_ text: String, maxChars: Int) -> String {
        let sentences = splitSentences(text)
        guard !sentences.isEmpty else {
            return truncateAtWord(text, maxChars: maxChars)
        }

        var picked: [String] = []
        var length = 0
        for sentence in sentences.prefix(4) {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 28 else { continue }
            let next = length + trimmed.count + (picked.isEmpty ? 0 : 1)
            if next > maxChars, !picked.isEmpty { break }
            picked.append(trimmed)
            length = next
            if picked.count >= 2, length >= min(180, maxChars) { break }
        }

        if picked.isEmpty {
            return truncateAtWord(text, maxChars: maxChars)
        }
        return picked.joined(separator: " ")
    }

    private static func splitSentences(_ text: String) -> [String] {
        var parts: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: [.bySentences, .localized]) { substring, _, _, _ in
            if let substring, !substring.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append(substring)
            }
        }
        return parts
    }

    private static func truncateAtWord(_ text: String, maxChars: Int) -> String {
        guard text.count > maxChars else { return text }
        let idx = text.index(text.startIndex, offsetBy: maxChars)
        var cut = String(text[..<idx])
        if let lastSpace = cut.lastIndex(of: " ") {
            cut = String(cut[..<lastSpace])
        }
        return cut.trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private static func stripHTML(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: #"<script[^>]*>[\s\S]*?</script>"#, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"<style[^>]*>[\s\S]*?</style>"#, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"<br\s*/?>"#, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"</p>"#, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        let entities: [(String, String)] = [
            ("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        text = text.replacingOccurrences(of: #"&#\d+;"#, with: " ", options: .regularExpression)
        return text
    }
}
