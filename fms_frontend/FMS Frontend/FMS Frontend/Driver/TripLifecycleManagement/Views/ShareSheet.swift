import SwiftUI
import UIKit

// MARK: - ShareSheet
// Wraps UIActivityViewController so PDFs (and any items) can be shared
// from a SwiftUI .sheet modifier.

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
