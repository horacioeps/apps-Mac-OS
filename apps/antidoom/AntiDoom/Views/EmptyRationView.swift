import SwiftUI

struct EmptyRationView: View {
    @EnvironmentObject private var store: RationStore

    var body: some View {
        ContentUnavailableView {
            Label("Sin ración", systemImage: "tray")
        } description: {
            Text(store.lastError ?? "Pulsa para cargar feeds RSS y tweets semilla.")
        } actions: {
            Button("Cargar ración") {
                Task { await store.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
