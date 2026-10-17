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

            Section("Fuentes RSS") {
                ForEach($store.feeds) { $feed in
                    Toggle(isOn: $feed.enabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feed.name)
                            Text(feed.feedURL.absoluteString)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                            Text(feed.kind.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("También en la ración") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Noticias: resumen extractivo on-device antes de mostrar.")
                    Text("Vault: trozos de Daily Notes (seed_notes.json, sync desde el Mac).")
                    Text("Tweets: seed_tweets.json local.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Próximo") {
                Text("Vault en vivo (carpeta Obsidian), grabadora, bookmarks y tweets API.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
