import SwiftUI

/// Sesión de lectura: Zoom (centro) + PDF opcional + Preguntador + Highlights.
struct BookSessionView: View {
    let book: BookItem
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var preguntador: PreguntadorStore
    @EnvironmentObject private var highlights: HighlightStore
    @StateObject private var chat = ChatService()

    @State private var fullText = ""
    @State private var root: ZoomNode?
    @State private var path = ZoomPath.root
    @State private var loading = true
    @State private var errorText: String?
    @State private var showChat = false
    @State private var tab: SessionTab = .zoom
    @State private var exportText: String?
    @State private var zoomMode: String = ""

    private enum SessionTab: String, CaseIterable, Identifiable {
        case zoom = "Zoom"
        case pages = "Páginas"
        case preguntador = "Preguntador"
        case highlights = "Highlights"
        var id: String { rawValue }
    }

    private var currentNode: ZoomNode? {
        guard let root else { return nil }
        return ZoomTreeService.node(at: path, in: root)
    }

    var body: some View {
        Group {
            if loading {
                ProgressView("Extrayendo texto y construyendo zoom…")
            } else if let errorText {
                ContentUnavailableView("No se pudo abrir", systemImage: "exclamationmark.triangle", description: Text(errorText))
            } else if let root {
                VStack(spacing: 0) {
                    Picker("Vista", selection: $tab) {
                        ForEach(SessionTab.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    switch tab {
                    case .zoom:
                        VStack(spacing: 0) {
                            if !zoomMode.isEmpty {
                                Text("Zoom: \(zoomMode)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            ZoomTreeView(
                                root: root,
                                path: $path,
                                onAskChat: { showChat = true },
                                onHighlight: { text in
                                    highlights.add(bookID: book.id, text: text, zoomNodeID: currentNode?.id)
                                }
                            )
                        }
                    case .pages:
                        pagesPane
                    case .preguntador:
                        PreguntadorView(book: book, root: root)
                    case .highlights:
                        highlightsPane
                    }
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await open() }
        .sheet(isPresented: $showChat) {
            if let node = currentNode {
                ChatSheet(chat: chat, bookTitle: book.title, node: node)
            }
        }
        .sheet(isPresented: Binding(
            get: { exportText != nil },
            set: { if !$0 { exportText = nil } }
        )) {
            NavigationStack {
                ScrollView {
                    Text(exportText ?? "")
                        .font(.body.monospaced())
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Export Readwise")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { exportText = nil }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pagesPane: some View {
        switch book.format {
        case .pdf:
            PDFKitView(url: book.fileURL)
        case .markdown, .plainText, .epub, .unknown:
            ScrollView {
                Text(fullText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
        }
    }

    private var highlightsPane: some View {
        List {
            Section {
                Button("Exportar Markdown (Readwise propio)") {
                    exportText = highlights.markdownExport(bookTitle: book.title, bookID: book.id)
                }
            }
            Section("Highlights") {
                let items = highlights.highlights.filter { $0.bookID == book.id }
                if items.isEmpty {
                    Text("Aún no hay highlights. En Zoom, mantén pulsado el verbatim.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { h in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(h.text)
                            if !h.note.isEmpty {
                                Text(h.note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx { highlights.delete(items[i]) }
                    }
                }
            }
        }
    }

    private func open() async {
        loading = true
        errorText = nil
        library.markOpened(book)
        do {
            let text = try await DocumentTextExtractor.extract(from: book)
            fullText = text
            var tree = ZoomTreeService.buildTree(title: book.title, fullText: text)
            let enriched = await ZoomTreeService.enrichWithLLM(root: tree, fullText: text)
            tree = enriched.0
            zoomMode = enriched.1
            root = tree
            path = .root
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}
