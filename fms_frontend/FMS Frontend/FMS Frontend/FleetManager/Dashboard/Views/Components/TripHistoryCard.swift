import SwiftUI

// MARK: - Trip History Card
struct TripHistoryCard: View {
    let trips: [VehicleTrip]
    var onSelect: ((VehicleTrip) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Trip History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(trips.count) trips")
                    .font(AppFonts.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(20)
            }

            if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No completed trips yet")
                        .font(AppFonts.body)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .accessibilityLabel("No completed trips yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(trips) { trip in
                        Button(action: { onSelect?(trip) }) {
                            TripHistoryRow(trip: trip)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("\(trip.origin) to \(trip.destination), completed on \(trip.date ?? "recently")")
                        .accessibilityHint("Double tap to view trip details")

                        if trip.id != trips.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(AppTheme.defaultCornerRadius)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Trip History Row
struct TripHistoryRow: View {
    let trip: VehicleTrip

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Route Icon
            ZStack {
                Circle()
                    .fill(AppTheme.activeGreen.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.activeGreen)
            }
            .accessibilityHidden(true)

            // Route info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(trip.origin)
                        .font(AppFonts.headline)
                        .foregroundColor(AppTheme.primary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Text(trip.destination)
                        .font(AppFonts.headline)
                        .foregroundColor(AppTheme.primary)
                }
                .lineLimit(1)

                HStack(spacing: 8) {
                    Text(trip.date ?? "Recently")
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)

                    if let dist = trip.distance {
                        Text("·")
                            .foregroundColor(.gray)
                        Text(dist)
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                    }

                    if let cost = trip.costEstimate {
                        Text("·")
                            .foregroundColor(.gray)
                        Text(cost)
                            .font(AppFonts.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primary.opacity(0.8))
                    }
                }
            }

            Spacer()

            // Status badge + chevron
            VStack(alignment: .trailing, spacing: 6) {
                Text("COMPLETED")
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.activeGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.activeGreen.opacity(0.1))
                    .cornerRadius(4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
