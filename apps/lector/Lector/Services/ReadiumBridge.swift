import Foundation
import ReadiumShared
import ReadiumStreamer

/// Apertura y extracción vía Readium (EPUB/PDF y formatos del toolkit).
enum ReadiumBridge {
    private static let httpClient = DefaultHTTPClient()
    private static let assetRetriever = AssetRetriever(httpClient: httpClient)
    private static let opener = PublicationOpener(
        parser: DefaultPublicationParser(
            httpClient: httpClient,
            assetRetriever: assetRetriever,
            pdfFactory: DefaultPDFDocumentFactory()
        )
    )
    private static let extractorFactory = DefaultResourceContentExtractorFactory()

    struct Opened {
        let publication: Publication
        let format: Format
    }

    /// Capítulo = un ítem del readingOrder (spine) con título de TOC si existe.
    struct Chapter: Sendable {
        let title: String
        let body: String
        let href: String
    }

    static func open(url: URL) async throws -> Opened {
        guard let fileURL = FileURL(url: url) else {
            throw BridgeError.invalidURL
        }
        let asset = try await assetRetriever.retrieve(url: fileURL).get()
        let publication = try await opener.open(asset: asset, allowUserInteraction: false).get()
        return Opened(publication: publication, format: asset.format)
    }

    /// Capítulos estructurados (para Zoom). Mejor que un blob plano.
    static func extractChapters(from url: URL, maxCharacters: Int = 800_000) async throws -> [Chapter] {
        let opened = try await open(url: url)
        let tocLinks = (try? await opened.publication.tableOfContents().get()) ?? opened.publication.manifest.tableOfContents
        let tocTitles = tocTitleIndex(tocLinks)
        var chapters: [Chapter] = []
        var total = 0
        var index = 0

        for link in opened.publication.readingOrder {
            if total >= maxCharacters { break }
            guard let resource = opened.publication.get(link) else { continue }

            let chunk: String?
            if let mediaType = link.mediaType,
               let extractor = extractorFactory.makeExtractor(for: resource, mediaType: mediaType) {
                chunk = try? await extractor.extractText(of: resource).get()
            } else {
                let data = try? await resource.read().get()
                chunk = data.flatMap { String(data: $0, encoding: .utf8) }.map(stripHTML)
            }

            guard var text = chunk?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                continue
            }
            if total + text.count > maxCharacters {
                text = String(text.prefix(maxCharacters - total))
            }
            // Saltar ruido mínimo (páginas casi vacías)
            guard text.count >= 40 else { continue }

            let href = link.href
            let title = resolveTitle(
                link: link,
                href: href,
                body: text,
                tocTitles: tocTitles,
                fallbackIndex: index + 1
            )
            chapters.append(Chapter(title: title, body: text, href: href))
            total += text.count
            index += 1
        }

        return chapters
    }

    /// Texto plano (compat). Prefiere unir capítulos.
    static func extractPlainText(from url: URL, maxCharacters: Int = 800_000) async throws -> String? {
        let chapters = try await extractChapters(from: url, maxCharacters: maxCharacters)
        guard !chapters.isEmpty else { return nil }
        return chapters.map(\.body).joined(separator: "\n\n")
    }

    // MARK: - TOC / títulos

    private static func tocTitleIndex(_ links: [Link]) -> [String: String] {
        var map: [String: String] = [:]
        func walk(_ items: [Link]) {
            for item in items {
                let href = item.href
                if let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                    map[normalizeHref(href)] = title
                    if let base = href.split(separator: "#").first {
                        map[normalizeHref(String(base))] = title
                    }
                }
                walk(item.children)
            }
        }
        walk(links)
        return map
    }

    private static func normalizeHref(_ href: String) -> String {
        href
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%20", with: " ")
            .lowercased()
    }

    private static func resolveTitle(
        link: Link,
        href: String,
        body: String,
        tocTitles: [String: String],
        fallbackIndex: Int
    ) -> String {
        let key = normalizeHref(href)
        let baseKey = normalizeHref(String(href.split(separator: "#").first.map(String.init) ?? href))
        if let t = tocTitles[key] ?? tocTitles[baseKey] { return cleanTitle(t) }
        if let t = link.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return cleanTitle(t)
        }
        if let fromBody = firstHeading(in: body) { return cleanTitle(fromBody) }
        return "Capítulo \(fallbackIndex)"
    }

    private static func firstHeading(in body: String) -> String? {
        for line in body.components(separatedBy: .newlines).prefix(12) {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard t.count >= 2, t.count <= 80 else { continue }
            if t.hasPrefix("#") {
                return String(t.drop(while: { $0 == "#" || $0 == " " }))
            }
            // Línea corta tipo título (no frase larga)
            if t.count <= 60,
               !t.hasSuffix("."),
               t.range(of: #"^(Part|Parte|Chapter|Cap[ií]tulo|Contents|Copyright)\b"#, options: [.regularExpression, .caseInsensitive]) != nil
                || t.split(separator: " ").count <= 8 {
                // Evitar TOC spam
                let lower = t.lowercased()
                if ["contents", "copyright", "title page", "epigraph"].contains(lower) { return t }
                if t.range(of: #"^(Part|Parte|Chapter|Cap[ií]tulo)\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                    return t
                }
            }
        }
        // Primera línea corta no vacía
        if let first = body.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) }).first(where: { !$0.isEmpty && $0.count <= 70 }) {
            let lower = first.lowercased()
            if lower == "contents" || lower.hasPrefix("copyright") { return first }
            if first.split(separator: " ").count <= 10 { return first }
        }
        return nil
    }

    private static func cleanTitle(_ t: String) -> String {
        String(t.prefix(100)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripHTML(_ raw: String) -> String {
        var s = raw
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            s = regex.stringByReplacingMatches(
                in: s,
                range: NSRange(s.startIndex..., in: s),
                withTemplate: " "
            )
        }
        return s
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    enum BridgeError: LocalizedError {
        case invalidURL
        var errorDescription: String? { "URL de archivo no válida para Readium." }
    }
}
