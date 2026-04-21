import SwiftUI

struct TripHistoryCard: View {
    let trips: [VehicleTrip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Trip History")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No recent activity")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(trips.prefix(4)) { trip in
                        TripHistoryRow(trip: trip)
                        if trip.id != trips.prefix(4).last?.id {
                            Divider().padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.defaultCornerRadius)
        .modifier(AppColors.cardShadow())
    }
}

struct TripHistoryRow: View {
    let trip: VehicleTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(trip.origin) → \(trip.destination)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            Text(trip.date ?? "Recently")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TripHistoryCard(trips: [
        VehicleTrip(origin: "DEL", destination: "JAI", progress: 1.0, eta: "Completed", date: "Yesterday", distance: "250 KM", duration: "4h", costEstimate: "₹8,500", startTime: nil, status: .completed),
        VehicleTrip(origin: "MUM", destination: "PUN", progress: 1.0, eta: "Completed", date: "2 days ago", distance: "150 KM", duration: "3h", costEstimate: "₹4,200", startTime: nil, status: .completed)
    ])
    .padding()
    .background(AppColors.secondaryBackground)
}
