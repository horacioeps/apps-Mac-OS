import Foundation

/// Nodo del árbol de zoom: de esquema amplio → verbatim.
struct ZoomNode: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var summary: String
    /// Texto fuente asociado (verbatim o extracto). Vacío en nodos solo-esquema.
    var verbatim: String
    var children: [ZoomNode]
    /// Offset aproximado en el texto plano del libro (para anclar lectura).
    var sourceStart: Int
    var sourceEnd: Int
    var depth: Int

    var isLeaf: Bool { children.isEmpty }

    var hasVerbatim: Bool { !verbatim.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    static func rootPlaceholder(title: String) -> ZoomNode {
        ZoomNode(
            id: UUID(),
            title: title,
            summary: "Generando esquema…",
            verbatim: "",
            children: [],
            sourceStart: 0,
            sourceEnd: 0,
            depth: 0
        )
    }
}

struct ZoomPath: Hashable {
    var nodeIDs: [UUID]

    static let root = ZoomPath(nodeIDs: [])
}
