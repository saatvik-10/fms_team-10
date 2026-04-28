//
//  PDFPreviewView.swift
//  FMS Frontend
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    
    @State private var pdfDocument: PDFDocument? = nil
    @State private var isLoading = true
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.4)
                        Text("Loading Report…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let doc = pdfDocument {
                    PDFKitDocumentView(document: doc)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Could not load report")
                            .font(.headline)
                        Text("The PDF file may have been removed from temporary storage.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Dismiss") { dismiss() }
                            .padding(.top, 8)
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
            // Load off the main thread so the view can animate in first
            let doc = await Task.detached(priority: .userInitiated) {
                PDFDocument(url: url)
            }.value
            
            self.pdfDocument = doc
            self.isLoading = false
        }
    }
}

/// A dedicated PDFView wrapper that takes an already-loaded PDFDocument.
/// This guarantees autoScales is applied after the view is laid out.
struct PDFKitDocumentView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.backgroundColor = .secondarySystemBackground
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false, withViewOptions: nil)
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
            uiView.autoScales = true
        }
    }
}
