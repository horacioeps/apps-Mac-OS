import Foundation

/// Clave OpenAI embebida (solo máquina local). `Secrets.Local.swift` (gitignored) la rellena al cargar.
enum BundledSecrets {
    static var openAIAPIKey: String = ""
}

enum AppSecrets {
    static var openAIAPIKey: String {
        BundledSecrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
