import SwiftUI

@main
struct AlarmaApp: App {
    @StateObject private var store = AlarmStore()

    var body: some Scene {
        WindowGroup {
            AlarmHomeView()
                .environmentObject(store)
        }
    }
}
