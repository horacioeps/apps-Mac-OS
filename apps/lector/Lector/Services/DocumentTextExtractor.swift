import Foundation
import PDFKit

/// Extrae texto plano para Zoom / Chat / Preguntador.
enum DocumentTextExtractor {
    static func extract(from book: BookItem) async throws -> String {
        switch book.format {
        case .markdown, .plainText:
            return try String(contentsOf: book.fileURL, encoding: .utf8)
        case .pdf:
            return try extractPDF(url: book.fileURL)
        case .epub, .unknown:
            if let viaReadium = try await ReadiumBridge.extractPlainText(from: book.fileURL) {
                return viaReadium
            }
            if book.format == .unknown,
               let text = try? String(contentsOf: book.fileURL, encoding: .utf8),
               !text.isEmpty {
                return text
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
