import SwiftUI

/// Pantalla central: un solo ítem de la ración. No hay scroll infinito.
struct RationView: View {
    @EnvironmentObject private var store: RationStore
    let item: RationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 16) {
                Text(item.kind.label.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Text(item.title)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.sourceName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                if let url = item.url {
                    Link(destination: url) {
                        Label(item.kind == .podcast ? "Escuchar / abrir" : "Abrir", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.markConsumed(item)
                    }
                } label: {
                    Text(store.remaining.count <= 1 ? "Terminar ración" : "Siguiente")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(min(store.consumedCount + 1, max(store.totalCount, 1))) de \(store.totalCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let total = max(store.totalCount, 1)
                let done = CGFloat(store.consumedCount) / CGFloat(total)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: max(8, geo.size.width * done))
                }
            }
            .frame(height: 4)
        }
    }
}
