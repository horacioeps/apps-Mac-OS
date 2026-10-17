import SwiftUI

struct FinishedView: View {
    @EnvironmentObject private var store: RationStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Ración terminada")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
            Text("Hoy no hay más. Ese es el punto.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Repetir ración de hoy") {
                store.resetRationForToday()
            }
            .buttonStyle(.bordered)
            Button("Nueva ración") {
                Task { await store.refresh() }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 28)
        }
        .padding()
    }
}
