import SwiftUI

struct ZoomTreeView: View {
    let root: ZoomNode
    @Binding var path: ZoomPath
    var onAskChat: () -> Void
    var onHighlight: (String) -> Void

    private var current: ZoomNode {
        ZoomTreeService.node(at: path, in: root)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                breadcrumb

                Text(current.title)
                    .font(.title2.weight(.semibold))

                Text(current.summary)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.9))
                    .textSelection(.enabled)

                if current.hasVerbatim {
                    Divider()
                    Text("Verbatim")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(current.verbatim)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button("Guardar highlight") {
                                onHighlight(current.verbatim)
                            }
                        }
                }

                if !current.children.isEmpty {
                    Divider()
                    Text("Zoom a… (\(current.children.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(current.children) { child in
                        Button {
                            TraceDump.shared.log("zoom", "tap child \(child.title)")
                            path.nodeIDs.append(child.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.title)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                    Text(child.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "plus.magnifyingglass")
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: onAskChat) {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                if !path.nodeIDs.isEmpty {
                    Button("Zoom out") {
                        _ = path.nodeIDs.popLast()
                    }
                }
            }
        }
    }

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                crumb(title: root.title, truncateTo: [])
                ForEach(Array(path.nodeIDs.enumerated()), id: \.offset) { idx, id in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    let partial = ZoomPath(nodeIDs: Array(path.nodeIDs.prefix(idx + 1)))
                    let node = ZoomTreeService.node(at: partial, in: root)
                    crumb(title: node.title, truncateTo: partial.nodeIDs)
                }
            }
        }
    }

    private func crumb(title: String, truncateTo ids: [UUID]) -> some View {
        Button(title) {
            path.nodeIDs = ids
        }
        .font(.caption.weight(.medium))
        .buttonStyle(.bordered)
    }
}
