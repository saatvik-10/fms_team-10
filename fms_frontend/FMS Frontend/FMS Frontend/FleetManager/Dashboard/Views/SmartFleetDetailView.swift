import SwiftUI

struct SmartFleetDetailView: View {
    let assessment: SmartFleetAssessment
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "truck.box.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .foregroundColor(AppColors.primary)
            
            Text(assessment.truckName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(assessment.truckID)
                .font(.headline)
                .foregroundColor(AppColors.textSecondary)
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    DetailRow(title: "Route", value: "\(assessment.routeFrom) to \(assessment.routeTo)")
                    DetailRow(title: "ETA", value: "\(assessment.etaTime) \(assessment.etaDay)")
                }
                GridRow {
                    DetailRow(title: "Status", value: "\(assessment.status)")
                    DetailRow(title: "Location", value: "34.0522° N, 118.2437° W")
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Vehicle Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.body)
        }
    }
}
