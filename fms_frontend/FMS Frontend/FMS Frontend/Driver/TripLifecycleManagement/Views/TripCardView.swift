import SwiftUI

struct TripCardView: View {
    let trip: LifecycleTrip
    
    // Callbacks for button actions
    var onAccept: (() -> Void)? = nil
    var onDecline: (() -> Void)? = nil
    var onStart: (() -> Void)? = nil
    var onViewSummary: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Row: ID and Status badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.id)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    if let vehicleNo = trip.vehicleNumber {
                        HStack(spacing: 4) {
                            Image(systemName: "box.truck.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(vehicleNo)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                Text(trip.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
            }
            
            // Route section with visual connector
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 28)
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                }
                
                VStack(alignment: .leading, spacing: 18) {
                    Text(trip.source)
                        .font(.headline)
                    Text(trip.destination)
                        .font(.headline)
                }
            }
            .padding(.vertical, 4)
            
            
            Divider()
            
            // Time & Info row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(trip.timeLabel)
                        Text("•")
                        Text(trip.dateValue)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text(trip.timeValue)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    Text(String(format: "%.1f km", trip.distance * 1.60934))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                }
            }
            
            // Action Buttons (vary by segment)
            HStack(spacing: 12) {
                if trip.segment == .assigned {
                    Button(action: { onDecline?() }) {
                        Text("Decline")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { onAccept?() }) {
                        Text("Accept Trip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "0a303a"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if trip.segment == .accepted {
                    Button(action: { onStart?() }) {
                        Text("View Trip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "0a303a"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if trip.segment == .past {
                    Button(action: { onViewSummary?() }) {
                        Text("View Report")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "0a303a"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}
