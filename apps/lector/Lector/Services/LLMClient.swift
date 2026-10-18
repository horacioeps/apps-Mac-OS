import Foundation

/// Cliente OpenAI Chat Completions. Clave en Keychain (Ajustes); nunca en el repo.
actor LLMClient {
    static let shared = LLMClient()

    enum LLMError: LocalizedError {
        case noAPIKey
        case badResponse(Int, String)
        case emptyContent
        case network(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: "Configura la API key de OpenAI en Ajustes."
            case .badResponse(let code, let body): "OpenAI \(code): \(body.prefix(200))"
            case .emptyContent: "Respuesta vacía del modelo."
            case .network(let e): e.localizedDescription
            }
        }
    }

    func isConfigured() -> Bool {
        LLMSettings.hasKey && LLMSettings.useLLM
    }

    func complete(
        system: String,
        user: String,
        temperature: Double = 0.3,
        maxTokens: Int = 1200
    ) async throws -> String {
        try await complete(
            messages: [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    func complete(
        messages: [[String: String]],
        temperature: Double = 0.4,
        maxTokens: Int = 1500
    ) async throws -> String {
        guard LLMSettings.useLLM else { throw LLMError.noAPIKey }
        guard let key = LLMSettings.apiKey, !key.isEmpty else { throw LLMError.noAPIKey }

        let payload: [String: Any] = [
            "model": LLMSettings.model,
            "temperature": temperature,
            "max_tokens": maxTokens,
            "messages": messages
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 90

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.network(error)
        }

        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw LLMError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw LLMError.emptyContent
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LLMError.emptyContent }
        return trimmed
    }
}
