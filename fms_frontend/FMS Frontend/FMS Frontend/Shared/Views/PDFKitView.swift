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
        pdfView.autoScales = true
        
        if let document = document {
            pdfView.document = document
        } else if let url = url {
            pdfView.document = PDFDocument(url: url)
        }
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = document {
            uiView.document = document
        } else if let url = url {
            // Only update if document changed or to avoid redundant loads
            if uiView.document?.documentURL != url {
                uiView.document = PDFDocument(url: url)
            }
        }
    }
}
