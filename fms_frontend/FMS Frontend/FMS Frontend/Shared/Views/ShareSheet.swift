import SwiftUI
internal import UIKit

// MARK: - ShareSheet
// Unified ShareSheet component to avoid build conflicts
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    // Backwards compatibility for usages using 'items'
    init(items: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = items
        self.applicationActivities = applicationActivities
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
