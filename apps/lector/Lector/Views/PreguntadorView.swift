import SwiftUI

struct PreguntadorView: View {
    @EnvironmentObject private var preguntador: PreguntadorStore
    let book: BookItem
    let root: ZoomNode?
    @State private var revealing = false
    @State private var current: ReviewCard?

    var body: some View {
        VStack(spacing: 20) {
            if let card = current ?? preguntador.dueCards.first(where: { $0.bookID == book.id }) {
                cardView(card)
            } else {
                ContentUnavailableView(
                    "Nada pendiente",
                    systemImage: "checkmark.circle",
                    description: Text("Genera tarjetas desde el zoom o vuelve más tarde.")
                )
                if root != nil {
                    Button("Generar desde zoom") {
                        seed()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("Preguntador")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Generar") { seed() }
                    .disabled(root == nil)
            }
        }
        .onAppear {
            current = preguntador.dueCards.first(where: { $0.bookID == book.id })
            revealing = false
        }
    }

    @ViewBuilder
    private func cardView(_ card: ReviewCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repetición espaciada")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(card.prompt)
                .font(.title3.weight(.semibold))
            if revealing {
                Text(card.answer)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    ForEach(ReviewGrade.allCases) { grade in
                        Button(grade.title) {
                            preguntador.grade(card, grade)
                            revealing = false
                            current = preguntador.dueCards.first(where: { $0.bookID == book.id })
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                Button("Mostrar respuesta") { revealing = true }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
            Text("\(preguntador.dueCards.filter { $0.bookID == book.id }.count) pendientes · \(preguntador.cards.filter { $0.bookID == book.id }.count) total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func seed() {
        guard let root else { return }
        preguntador.seedFromZoom(book: book, root: root)
        current = preguntador.dueCards.first(where: { $0.bookID == book.id })
        revealing = false
    }
}
