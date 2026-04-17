import SwiftUI

struct TripsView: View {
    @StateObject private var viewModel = TripsViewModel()
    @State private var tripToNavigate: LifecycleTrip?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header: Title + Segmented control
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Trips")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Active logistics management")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        Picker("Trip Status", selection: $viewModel.selectedSegment) {
                            ForEach(TripSegment.allCases, id: \.self) { segment in
                                Text(segment.rawValue).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .padding(.top, 16)
                    .background(Color(UIColor.systemBackground))
                    
                    // Trip card list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredTrips) { trip in
                                TripCardView(
                                    trip: trip,
                                    onAccept: { viewModel.acceptTrip(trip) },
                                    onDecline: { viewModel.declineTrip(trip) },
                                    onStart: { tripToNavigate = trip },
                                    onViewSummary: { viewModel.viewSummary(trip) }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { tripToNavigate != nil },
                set: { if !$0 { tripToNavigate = nil } }
            )) {
                if let selected = tripToNavigate {
                    TripDetailView(trip: selected.toTripModel())
                }
            }
        }
    }
}

#Preview {
    TripsView()
}
