import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: RationStore

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.items.isEmpty {
                    ProgressView("Preparando tu ración…")
                } else if store.isFinished {
                    FinishedView()
                } else if let item = store.current {
                    RationView(item: item)
                } else {
                    EmptyRationView()
                }
            }
            .navigationTitle("AntiDoom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                if store.items.isEmpty {
                    await store.refresh()
                }
            }
        }
    }
}
