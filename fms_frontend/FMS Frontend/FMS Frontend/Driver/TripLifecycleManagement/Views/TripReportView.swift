import SwiftUI
import PDFKit

// MARK: - PDF Viewer Screen
// Displayed when the driver taps "View Summary" on a past trip.
// Shows the generated report inline with a back button (top-left)
// and a share button (top-right).

struct TripReportView: View {
    let trip: LifecycleTrip

    @Environment(\.dismiss) private var dismiss
    @State private var pdfDocument: PDFDocument? = nil
    @State private var isLoading: Bool = true
    @State private var showShareSheet: Bool = false
    @State private var pdfURL: URL? = nil

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            if isLoading {
                // ── Loading state ────────────────────────────────
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.4)
                    Text("Generating Report…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

            } else if let doc = pdfDocument {
                // ── Inline PDF viewer ─────────────────────────────
                PDFKitView(document: doc)
                    .ignoresSafeArea(edges: .bottom)

            } else {
                // ── Error state ───────────────────────────────────
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Could not generate report.")
                        .font(.headline)
                    Text("Please try again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(trip.id)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        // ── Custom back button (top-left) ─────────────────────
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("Back")
                    }
                    .foregroundColor(.primary)
                }
            }

            // ── Share button (top-right) ──────────────────────
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .disabled(pdfURL == nil)
            }
        }
        // ── Share sheet ───────────────────────────────────────
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        // ── Generate PDF on appear ────────────────────────────
        .task {
            await generatePDF()
        }
    }

    // MARK: – PDF Generation

    private func generatePDF() async {
        // Build data off the main actor, then publish results on it.
        let trip = self.trip   // capture value type — safe to cross actor boundary

        let (pdfData, url): (Data, URL) = await Task.detached(priority: .userInitiated) {
            // nonisolated context: call through nonisolated static helpers
            let reportData = await MainActor.run { TripReportData.mock(from: trip) }
            let pdfData    = await MainActor.run { TripReportGenerator().generate(from: reportData) }

            let fileName = "TripReport_\(trip.id).pdf"
            let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent(fileName)
            try? pdfData.write(to: url)
            return (pdfData, url)
        }.value

        let document = PDFDocument(data: pdfData)

        self.pdfDocument = document
        self.pdfURL      = url
        self.isLoading   = false
    }
}

