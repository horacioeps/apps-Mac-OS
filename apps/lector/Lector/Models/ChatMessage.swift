import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: ChatRole
    let text: String
    let createdAt: Date
    /// Nodo de zoom que contextualizaba la pregunta, si aplica.
    var zoomNodeID: UUID?

    init(id: UUID = UUID(), role: ChatRole, text: String, createdAt: Date = .now, zoomNodeID: UUID? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.zoomNodeID = zoomNodeID
    }
}
