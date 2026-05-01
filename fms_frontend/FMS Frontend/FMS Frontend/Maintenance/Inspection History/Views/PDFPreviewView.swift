//
//  PDFPreviewView.swift
//  Created by Gargee Mohairr
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var pdfDocument: PDFDocument?
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            Group {
                if let document = pdfDocument {
                    PDFKitDocumentView(document: document)
                        .ignoresSafeArea(edges: .bottom)
                } else if loadFailed {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Failed to load PDF")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Report")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(pdfDocument == nil)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            let doc = await Task.detached(priority: .userInitiated) {
                PDFDocument(url: url)
            }.value
            if let doc = doc {
                pdfDocument = doc
            } else {
                loadFailed = true
            }
        }
    }
}

struct PDFKitDocumentView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No-op: document is set once in makeUIView
    }
}
