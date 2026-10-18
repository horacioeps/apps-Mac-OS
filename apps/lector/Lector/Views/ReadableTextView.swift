import SwiftUI

/// Texto de lectura bien renderizado (Markdown → tipografía; plano → párrafos).
struct ReadableTextView: View {
    let text: String
    var treatAsMarkdown: Bool = false

    var body: some View {
        ScrollView {
            Group {
                if treatAsMarkdown, let attributed = Self.markdown(text) {
                    Text(attributed)
                } else if treatAsMarkdown {
                    // Fallback si AttributedString falla: bloques tipográficos caseros
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(Self.simpleBlocks(text).enumerated()), id: \.offset) { _, block in
                            blockView(block)
                        }
                    }
                } else {
                    Text(text)
                        .font(.body)
                        .lineSpacing(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func blockView(_ block: TextBlock) -> some View {
        switch block {
        case .h1(let t):
            Text(t).font(.largeTitle.weight(.bold)).padding(.top, 8)
        case .h2(let t):
            Text(t).font(.title2.weight(.semibold)).padding(.top, 10)
        case .h3(let t):
            Text(t).font(.title3.weight(.semibold)).padding(.top, 6)
        case .body(let t):
            Text(t).font(.body).lineSpacing(4)
        }
    }

    private enum TextBlock {
        case h1(String), h2(String), h3(String), body(String)
    }

    private static func markdown(_ source: String) -> AttributedString? {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.failurePolicy = .returnPartiallyParsedIfPossible
        return try? AttributedString(markdown: source, options: options)
    }

    private static func simpleBlocks(_ source: String) -> [TextBlock] {
        var blocks: [TextBlock] = []
        var paragraph: [String] = []

        func flush() {
            let p = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !p.isEmpty { blocks.append(.body(p)) }
            paragraph = []
        }

        for raw in source.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
                continue
            }
            if line.hasPrefix("### ") {
                flush()
                blocks.append(.h3(String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                flush()
                blocks.append(.h2(String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                flush()
                blocks.append(.h1(String(line.dropFirst(2))))
            } else {
                paragraph.append(line)
            }
        }
        flush()
        return blocks
    }
}
