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

    static func open(url: URL) async throws -> Opened {
        guard let fileURL = FileURL(url: url) else {
            throw BridgeError.invalidURL
        }
        let asset = try await assetRetriever.retrieve(url: fileURL).get()
        let publication = try await opener.open(asset: asset, allowUserInteraction: false).get()
        return Opened(publication: publication, format: asset.format)
    }

    /// Texto plano para ZoomTree (capado para no saturar memoria en libros enormes).
    static func extractPlainText(from url: URL, maxCharacters: Int = 400_000) async throws -> String? {
        let opened = try await open(url: url)
        var buffer = ""

        for link in opened.publication.readingOrder {
            if buffer.count >= maxCharacters { break }
            guard let resource = opened.publication.get(link) else { continue }

            let chunk: String?
            if let mediaType = link.mediaType,
               let extractor = extractorFactory.makeExtractor(for: resource, mediaType: mediaType) {
                chunk = try? await extractor.extractText(of: resource).get()
            } else {
                let data = try? await resource.read().get()
                chunk = data.flatMap { String(data: $0, encoding: .utf8) }.map(stripHTML)
            }

            guard let text = chunk?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                continue
            }
            if !buffer.isEmpty { buffer += "\n\n" }
            buffer += text
        }

        let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(maxCharacters))
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
