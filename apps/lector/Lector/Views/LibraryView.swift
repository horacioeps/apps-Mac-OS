import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var showImporter = false
    @State private var importError: String?

    var body: some View {
        List {
            Section {
                Text("Zoom multinivel · Chat · Preguntador · Highlights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Biblioteca") {
                ForEach(library.books) { book in
                    NavigationLink(value: book) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(book.format.displayName)
                                Text("·")
                                Text(book.sourceLabel)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        library.delete(library.books[i])
                    }
                }
            }

            Section("Fuentes (próximo)") {
                Label("Apple Books / Kindle: export sin DRM → Importar", systemImage: "square.and.arrow.down")
                Label("Zotero seleccionados: API / adjuntos", systemImage: "books.vertical")
            }
        }
        .navigationTitle("Lector")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImporter = true
                } label: {
                    Label("Importar", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.pdf, .epub, .plainText, .utf8PlainText, UTType(filenameExtension: "md")].compactMap { $0 },
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    do {
                        _ = try library.importFile(from: url)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("Importación", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
}

private extension UTType {
    static var epub: UTType { UTType(filenameExtension: "epub") ?? .data }
}
