import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL
    var goToPage: Int?

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
        if let goToPage, let page = uiView.document?.page(at: goToPage) {
            uiView.go(to: page)
        }
    }
}
