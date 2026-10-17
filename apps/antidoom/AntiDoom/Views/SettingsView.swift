import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: RationStore

    var body: some View {
        Form {
            Section("Ración") {
                Stepper(value: $store.rationSize, in: 3...15) {
                    Text("Tamaño: \(store.rationSize)")
                }
                Button("Recargar ración ahora") {
                    Task { await store.refresh() }
                }
            }

            Section("Feeds RSS (v1)") {
                ForEach($store.feeds) { $feed in
                    Toggle(isOn: $feed.enabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feed.name)
                            Text(feed.kind.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Próximo") {
                Text("Vault de notas, grabadora, bookmarks y tweets en vivo → v1.1")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
