import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = LLMSettings.apiKey ?? ""
    @State private var model: String = LLMSettings.model
    @State private var useLLM: Bool = LLMSettings.useLLM
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Toggle("Usar OpenAI para Zoom / Chat / Preguntador", isOn: $useLLM)
                SecureField("API key (sk-…)", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Modelo", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Clave embebida en build local (Secrets.Local, fuera del repo) y/o Keychain. App privada.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("OpenAI")
            }

            Section("Estado") {
                Label(
                    LLMSettings.hasKey ? "API key lista (embebida o Keychain)" : "Sin API key",
                    systemImage: LLMSettings.hasKey ? "checkmark.seal.fill" : "key.slash"
                )
                Text("Modelo activo: \(LLMSettings.model)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("TEDx / Preguntador") {
                Text("Cajas Leitner + cola de sesión de MemorizaGuion (TEDX Almería 2026 / app/repeticion espaciada iOS). Generación LLM con pistas progresivas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    LLMSettings.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    LLMSettings.model = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "gpt-4o-mini"
                        : model.trimmingCharacters(in: .whitespacesAndNewlines)
                    LLMSettings.useLLM = useLLM
                    saved = true
                }
            }
        }
        .alert("Guardado", isPresented: $saved) {
            Button("OK", role: .cancel) {}
        }
    }
}
