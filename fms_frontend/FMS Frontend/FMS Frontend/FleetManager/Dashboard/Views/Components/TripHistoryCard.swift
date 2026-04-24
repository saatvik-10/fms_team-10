import SwiftUI

struct TripHistoryCard: View {
    let trips: [VehicleTrip]
    var onSelect: ((VehicleTrip) -> Void)? = nil
    var onViewAll: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Trip History")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Button(action: { onViewAll?() }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(AppFonts.caption2)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppColors.primary.opacity(0.6))
                }
            }
            
            if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No recent activity")
                        .font(AppFonts.body)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(trips.prefix(4)) { trip in
                        Button(action: { onSelect?(trip) }) {
                            TripHistoryRow(trip: trip)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if trip.id != trips.prefix(4).last?.id {
                            Divider().padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.defaultCornerRadius)
        .modifier(AppColors.cardShadow())
    }
}

struct TripHistoryRow: View {
    let trip: VehicleTrip
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.origin) → \(trip.destination)")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                
                Text(trip.date ?? "Recently")
                    .font(AppFonts.footnote)
                    .foregroundColor(.gray)
                    .italic()
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.status.rawValue)
                        .font(AppFonts.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.activeGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.activeGreen.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    TripHistoryCard(trips: [
        VehicleTrip(vehicleID: "DEMO-1", origin: "DEL", destination: "JAI", progress: 1.0, eta: "Completed", date: "Yesterday", distance: "250 KM", duration: "4h", costEstimate: "₹8,500", startTime: nil, status: .completed, productType: "Electronic Goods", loadAmount: "2.5 Tons"),
        VehicleTrip(vehicleID: "DEMO-2", origin: "MUM", destination: "PUN", progress: 1.0, eta: "Completed", date: "2 days ago", distance: "150 KM", duration: "3h", costEstimate: "₹4,200", startTime: nil, status: .completed, productType: "Auto Parts", loadAmount: "5.0 Tons")
    ])
    .padding()
    .background(AppColors.secondaryBackground)
}
