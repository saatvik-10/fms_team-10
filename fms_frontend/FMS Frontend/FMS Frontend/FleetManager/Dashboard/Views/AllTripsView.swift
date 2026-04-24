import SwiftUI

struct AllTripsView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTrip: VehicleTrip?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.secondaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Complete Trip History")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if dataManager.allHistory.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("No historical records found")
                                    .font(AppFonts.body)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(dataManager.allHistory) { trip in
                                    Button(action: { selectedTrip = trip }) {
                                        TripHistoryRow(trip: trip)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if trip.id != dataManager.allHistory.last?.id {
                                        Divider().padding(.vertical, 8)
                                    }
                                }
                            }
                            .padding(24)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppColors.defaultCornerRadius)
                            .modifier(AppColors.cardShadow())
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Trip History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .fullScreenCover(item: $selectedTrip) { trip in
                TripDetailNavigationWrapper(trip: trip)
            }
        }
    }
}

// Helper wrapper to find vehicle for history selection
struct TripDetailNavigationWrapper: View {
    let trip: VehicleTrip
    @EnvironmentObject var dataManager: FleetDataManager
    
    var body: some View {
        if let index = dataManager.vehicles.firstIndex(where: { $0.id == trip.vehicleID }) {
            FleetTripDetailView(vehicle: $dataManager.vehicles[index], tripOverride: trip)
        } else {
            Text("Error: Vehicle not found")
                .font(AppFonts.headline)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    AllTripsView()
        .environmentObject(FleetDataManager())
}
