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
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // maxHeight: el ScrollView hijo necesita altura acotada o no hace scroll.
                    Group {
                        switch tab {
                        case .zoom:
                            VStack(spacing: 0) {
                                if !zoomMode.isEmpty {
                                    Text("Zoom: \(zoomMode)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.bottom, 4)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await open() }
        .onChange(of: tab) { _, new in
            TraceDump.shared.setContext("tab", new.rawValue)
            TraceDump.shared.log("ui", "tab → \(new.rawValue)")
        }
        .onChange(of: path.nodeIDs) { _, ids in
            TraceDump.shared.setContext("zoomPathDepth", "\(ids.count)")
            if let node = currentNode {
                TraceDump.shared.setContext("zoomNode", node.title)
                TraceDump.shared.log("zoom", "path depth=\(ids.count) node=\(node.title)", data: [
                    "children": "\(node.children.count)",
                    "summaryChars": "\(node.summary.count)",
                    "verbatimChars": "\(node.verbatim.count)"
                ])
            }
        }
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
        Group {
            switch book.format {
            case .pdf:
                PDFKitView(url: book.fileURL)
            case .markdown:
                ReadableTextView(text: fullText, treatAsMarkdown: true)
            case .plainText, .epub, .unknown:
                // EPUB entero (~800k) en un solo Text mata el scroll; cap suave + aviso.
                if fullText.count > 120_000 {
                    VStack(spacing: 0) {
                        Text("Vista Páginas: extracto inicial. Usa Zoom para navegar por capítulos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.08))
                        ReadableTextView(
                            text: String(fullText.prefix(120_000)) + "\n\n[…]",
                            treatAsMarkdown: false
                        )
                    }
                } else {
                    ReadableTextView(text: fullText, treatAsMarkdown: false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        TraceDump.shared.setContext("bookTitle", book.title)
        TraceDump.shared.setContext("bookFormat", book.format.rawValue)
        TraceDump.shared.setContext("bookPath", book.relativePath)
        TraceDump.shared.log("book", "Abriendo \(book.title)", data: [
            "format": book.format.rawValue,
            "path": book.relativePath
        ])
        do {
            let extraction = try await DocumentTextExtractor.extract(from: book)
            let text = extraction.fullText
            fullText = text
            TraceDump.shared.setContext("textChars", "\(text.count)")
            TraceDump.shared.setContext("chapterCount", "\(extraction.chapters.count)")
            TraceDump.shared.log("book", "Texto extraído", data: [
                "chars": "\(text.count)",
                "chapters": "\(extraction.chapters.count)",
                "preview": String(text.prefix(240)),
                "chapterTitles": extraction.chapters.prefix(8).map(\.title).joined(separator: " | ")
            ])
            var tree: ZoomNode
            if !extraction.chapters.isEmpty {
                tree = ZoomTreeService.buildTree(title: book.title, chapters: extraction.chapters)
            } else {
                tree = ZoomTreeService.buildTree(title: book.title, fullText: text)
            }
            TraceDump.shared.log("zoom", "Árbol extractivo", data: [
                "children": "\(tree.children.count)",
                "rootSummaryChars": "\(tree.summary.count)",
                "childTitles": tree.children.map(\.title).prefix(12).joined(separator: " | ")
            ])
            let enriched = await ZoomTreeService.enrichWithLLM(root: tree, fullText: text)
            tree = enriched.0
            zoomMode = enriched.1
            TraceDump.shared.setContext("zoomMode", zoomMode)
            TraceDump.shared.log("zoom", "Árbol listo mode=\(zoomMode)", data: [
                "children": "\(tree.children.count)",
                "rootSummaryChars": "\(tree.summary.count)",
                "childTitles": tree.children.map(\.title).prefix(12).joined(separator: " | ")
            ])
            root = tree
            path = .root
            TraceDump.shared.setContext("tab", tab.rawValue)
        } catch {
            errorText = error.localizedDescription
            TraceDump.shared.log("error", "open failed", data: ["error": error.localizedDescription])
        }
        loading = false
        // Tras pintar la UI: captura real (no el spinner).
        try? await Task.sleep(nanoseconds: 250_000_000)
        TraceDump.shared.dump(
            reason: errorText == nil ? "book-opened" : "book-open-error",
            extraState: [
                "childCount": "\(root?.children.count ?? 0)",
                "textChars": "\(fullText.count)",
                "zoomMode": zoomMode,
                "error": errorText ?? ""
            ]
        )
    }
}
