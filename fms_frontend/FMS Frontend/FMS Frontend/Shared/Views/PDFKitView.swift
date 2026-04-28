import SwiftUI
import PDFKit

// MARK: - PDFKitView
// Unified PDF viewer component to avoid build conflicts
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    let url: URL?

    init(document: PDFDocument) {
        self.document = document
        self.url = nil
    }

    init(url: URL) {
        self.url = url
        self.document = nil
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.backgroundColor = .secondarySystemBackground
        
        if let document = document {
            pdfView.document = document
        } else if let url = url {
            pdfView.document = PDFDocument(url: url)
        }
        
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = document {
            if uiView.document != document {
                uiView.document = document
                uiView.autoScales = true
            }
        } else if let url = url {
            if uiView.document?.documentURL != url {
                uiView.document = PDFDocument(url: url)
                uiView.autoScales = true
            }
        }
    }
}
