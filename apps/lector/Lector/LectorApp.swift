import SwiftUI

@main
struct LectorApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var preguntador = PreguntadorStore()
    @StateObject private var highlights = HighlightStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(preguntador)
                .environmentObject(highlights)
        }
    }
}
