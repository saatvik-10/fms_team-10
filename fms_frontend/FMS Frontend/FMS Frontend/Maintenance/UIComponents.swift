//
//  UIComponents.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import PDFKit

/// A premium, enterprise-level card container following iOS HIG.
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.03), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

/// A subtle, professional status indicator.
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

/// A standard iOS native action button for enterprise flows.
struct ActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color.clear)
            .foregroundColor(isSelected ? .white : color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1.5)
            )
        }
    }
}

/// A professional primary button for bottom actions.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

/// A native PDFKit wrapper for SwiftUI to view generated reports.
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // We typically don't need to update the document here unless the URL changes dynamically
    }
}
