import SwiftUI
import UIKit

/// Texto de lectura bien renderizado y con scroll fiable (UITextView).
struct ReadableTextView: View {
    let text: String
    var treatAsMarkdown: Bool = false

    var body: some View {
        ScrollableTextRepresentable(
            attributed: treatAsMarkdown ? Self.attributedMarkdown(text) : Self.attributedPlain(text)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static func attributedPlain(_ source: String) -> NSAttributedString {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 4
        para.paragraphSpacing = 8
        return NSAttributedString(
            string: source,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label,
                .paragraphStyle: para
            ]
        )
    }

    private static func attributedMarkdown(_ source: String) -> NSAttributedString {
        if let md = try? AttributedString(
            markdown: source,
            options: {
                var o = AttributedString.MarkdownParsingOptions()
                o.interpretedSyntax = .full
                o.failurePolicy = .returnPartiallyParsedIfPossible
                return o
            }()
        ) {
            return NSAttributedString(md)
        }
        // Fallback tipográfico casero
        let out = NSMutableAttributedString()
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let h1 = UIFont.preferredFont(forTextStyle: .largeTitle).bold()
        let h2 = UIFont.preferredFont(forTextStyle: .title2).bold()
        let h3 = UIFont.preferredFont(forTextStyle: .title3).bold()
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 4
        para.paragraphSpacing = 10

        for raw in source.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                out.append(NSAttributedString(string: "\n"))
                continue
            }
            let (font, content): (UIFont, String) = {
                if line.hasPrefix("### ") { return (h3, String(line.dropFirst(4))) }
                if line.hasPrefix("## ") { return (h2, String(line.dropFirst(3))) }
                if line.hasPrefix("# ") { return (h1, String(line.dropFirst(2))) }
                return (bodyFont, line)
            }()
            out.append(NSAttributedString(string: content + "\n", attributes: [
                .font: font,
                .foregroundColor: UIColor.label,
                .paragraphStyle: para
            ]))
        }
        return out
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let d = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: d, size: pointSize)
    }
}

/// UITextView con scroll nativo (evita el bug de ScrollView sin altura en VStack).
private struct ScrollableTextRepresentable: UIViewRepresentable {
    let attributed: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        tv.textContainer.lineFragmentPadding = 0
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = true
        tv.adjustsFontForContentSizeCategory = true
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributed {
            uiView.attributedText = attributed
            uiView.setContentOffset(.zero, animated: false)
        }
    }
}
