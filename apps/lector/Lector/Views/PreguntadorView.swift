import SwiftUI

struct PreguntadorView: View {
    @EnvironmentObject private var preguntador: PreguntadorStore
    let book: BookItem
    let root: ZoomNode?
    @State private var revealing = false
    @State private var hintIndex = 0
    @State private var queue: ReviewSessionQueue?
    @State private var current: ReviewCard?
    @State private var generating = false
    @State private var quedan = 0

    var body: some View {
        VStack(spacing: 20) {
            if let card = current {
                cardView(card)
            } else {
                ContentUnavailableView(
                    "Nada pendiente",
                    systemImage: "checkmark.circle",
                    description: Text("Genera tarjetas (LLM o extractivo) y empieza sesión.")
                )
                generateButtons
            }
            if !preguntador.statusMessage.isEmpty {
                Text(preguntador.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Preguntador")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Generar") {
                    Button("Con LLM (TEDx / escaletas)") {
                        Task { await generateLLM() }
                    }
                    .disabled(root == nil || generating)
                    Button("Extractivo (sin LLM)") {
                        seedExtractive()
                    }
                    .disabled(root == nil)
                    Button("Nueva sesión (vencidas)") {
                        startSession()
                    }
                }
            }
        }
        .onAppear { startSession() }
        .overlay {
            if generating { ProgressView("Generando…").padding().background(.ultraThinMaterial) }
        }
    }

    private var generateButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await generateLLM() }
            } label: {
                Label("Generar con LLM", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(root == nil || generating)

            Button("Generar extractivo") { seedExtractive() }
                .buttonStyle(.bordered)
                .disabled(root == nil)
        }
    }

    @ViewBuilder
    private func cardView(_ card: ReviewCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nivel \(card.detailLevel) · caja \(card.caja) · Leitner TEDx")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("quedan \(quedan)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(card.prompt)
                .font(.title3.weight(.semibold))

            if hintIndex > 0 {
                ForEach(Array(card.hints.prefix(hintIndex).enumerated()), id: \.offset) { _, hint in
                    Text("Pista: \(hint)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            if revealing {
                Text(card.answer)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    Button("↻ Reintentar") { answer(ok: false) }
                        .buttonStyle(.bordered)
                    Button("✓ OK") { answer(ok: true) }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                HStack {
                    if hintIndex < card.hints.count {
                        Button("💡 Pista") { hintIndex += 1 }
                            .buttonStyle(.bordered)
                    }
                    Button("Ver") { revealing = true }
                        .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }
    }

    private func startSession() {
        let due = preguntador.dueCards(for: book.id)
        queue = ReviewSessionQueue(cards: due)
        revealing = false
        hintIndex = 0
        syncCurrent()
    }

    private func syncCurrent() {
        current = queue?.current
        quedan = queue?.quedan ?? 0
        revealing = false
        hintIndex = 0
    }

    private func answer(ok: Bool) {
        guard let q = queue, let result = q.responder(ok: ok) else { return }
        preguntador.grade(result.card, ok ? .good : .again, primera: result.primera)
        syncCurrent()
    }

    private func seedExtractive() {
        guard let root else { return }
        preguntador.seedFromZoom(book: book, root: root)
        startSession()
    }

    private func generateLLM() async {
        guard let root else { return }
        generating = true
        await preguntador.seedWithLLM(book: book, root: root)
        generating = false
        startSession()
    }
}
