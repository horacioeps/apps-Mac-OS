import SwiftUI

@main
struct AntiDoomApp: App {
    @StateObject private var store = RationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
