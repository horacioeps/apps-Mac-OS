import SwiftUI

struct ChatSheet: View {
    @ObservedObject var chat: ChatService
    let bookTitle: String
    let node: ZoomNode
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chat.messages.filter { $0.role != .system }) { msg in
                                bubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chat.messages.count) { _, _ in
                        if let last = chat.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                HStack(alignment: .bottom) {
                    TextField("Pregunta sobre este zoom…", text: $draft, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button {
                        let q = draft
                        draft = ""
                        Task { await chat.ask(q, bookTitle: bookTitle, node: node) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chat.isThinking)
                }
                .padding()
            }
            .navigationTitle("Chat · \(node.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onAppear {
                chat.reset(for: bookTitle, node: node)
            }
        }
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }
            Text(msg.text)
                .padding(12)
                .background(msg.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            if msg.role != .user { Spacer(minLength: 40) }
        }
    }
}
