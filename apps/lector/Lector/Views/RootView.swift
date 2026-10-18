import SwiftUI

struct RootView: View {
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            LibraryView()
                .navigationDestination(for: BookItem.self) { book in
                    BookSessionView(book: book)
                }
        }
    }
}
