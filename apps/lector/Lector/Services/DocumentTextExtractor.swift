import Foundation
import PDFKit

/// Extrae texto / capítulos para Zoom / Chat / Preguntador.
enum DocumentTextExtractor {
    struct Extraction {
        let fullText: String
        let chapters: [ReadiumBridge.Chapter]
    }

    static func extract(from book: BookItem) async throws -> Extraction {
        switch book.format {
        case .markdown, .plainText:
            let text = try String(contentsOf: book.fileURL, encoding: .utf8)
            return Extraction(fullText: text, chapters: [])
        case .pdf:
            let text = try extractPDF(url: book.fileURL)
            return Extraction(fullText: text, chapters: [])
        case .epub, .unknown:
            if book.format == .epub || book.fileURL.pathExtension.lowercased() == "epub" {
                let chapters = try await ReadiumBridge.extractChapters(from: book.fileURL)
                if !chapters.isEmpty {
                    let full = chapters.map(\.body).joined(separator: "\n\n")
                    return Extraction(fullText: full, chapters: chapters)
                }
            }
            if let viaReadium = try await ReadiumBridge.extractPlainText(from: book.fileURL) {
                return Extraction(fullText: viaReadium, chapters: [])
            }
            if book.format == .unknown,
               let text = try? String(contentsOf: book.fileURL, encoding: .utf8),
               !text.isEmpty {
                return Extraction(fullText: text, chapters: [])
            }
            throw ExtractError.unsupportedFormat
        }
    }

    private static func extractPDF(url: URL) throws -> String {
        guard let doc = PDFDocument(url: url) else { throw ExtractError.unreadablePDF }
        var parts: [String] = []
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let s = page.string {
                parts.append(s)
            }
        }
        let joined = parts.joined(separator: "\n\n")
        if joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ExtractError.emptyText
        }
        return joined
    }

    enum ExtractError: LocalizedError {
        case unsupportedFormat
        case unreadablePDF
        case emptyText

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat: "Formato no soportado aún (exporta sin DRM a PDF/EPUB/MD)."
            case .unreadablePDF: "No se pudo abrir el PDF."
            case .emptyText: "El documento no tiene texto extraíble (¿escaneado sin OCR?)."
            }
        }
    }
}
