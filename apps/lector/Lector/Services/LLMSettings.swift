import Foundation
import Security

enum LLMSettings {
    private static let keyService = "com.horacioeps.lector"
    private static let keyAccount = "openai_api_key"
    private static let modelKey = "lector.openai.model"
    private static let useLLMKey = "lector.openai.enabled"

    static var model: String {
        get { UserDefaults.standard.string(forKey: modelKey) ?? "gpt-4o-mini" }
        set { UserDefaults.standard.set(newValue, forKey: modelKey) }
    }

    static var useLLM: Bool {
        get {
            if UserDefaults.standard.object(forKey: useLLMKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: useLLMKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: useLLMKey) }
    }

    static var apiKey: String? {
        get {
            if let stored = KeychainStore.read(service: keyService, account: keyAccount), !stored.isEmpty {
                return stored
            }
            let bundled = AppSecrets.openAIAPIKey
            return bundled.isEmpty ? nil : bundled
        }
        set {
            if let newValue, !newValue.isEmpty {
                KeychainStore.write(service: keyService, account: keyAccount, value: newValue)
            } else {
                KeychainStore.delete(service: keyService, account: keyAccount)
            }
        }
    }

    static var hasKey: Bool { apiKey?.isEmpty == false }

    /// Si hay clave embebida (Secrets.Local) y el Keychain está vacío, la copia al Keychain.
    static func seedKeychainFromBundleIfNeeded() {
        guard KeychainStore.read(service: keyService, account: keyAccount)?.isEmpty != false else { return }
        let bundled = AppSecrets.openAIAPIKey
        guard !bundled.isEmpty else { return }
        KeychainStore.write(service: keyService, account: keyAccount, value: bundled)
    }
}

enum KeychainStore {
    static func write(service: String, account: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
