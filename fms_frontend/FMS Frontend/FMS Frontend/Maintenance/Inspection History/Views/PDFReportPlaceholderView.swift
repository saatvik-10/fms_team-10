import SwiftUI
import PDFKit

struct PDFReportPlaceholderView: View {
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.primary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            
            Divider()
            
            // PDF Content Placeholder
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("Inspection Report Generated")
                            .font(.title3.bold())
                        Text("This is a high-fidelity PDF report of the \(title).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Mock PDF Content lines
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<10) { _ in
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 12)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
