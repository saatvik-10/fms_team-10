import SwiftUI

struct TripsView: View {
    @StateObject private var viewModel = TripsViewModel()

    // Navigation destinations
    @State private var tripToNavigate: LifecycleTrip?   // "View Trip" → TripDetailView
    @State private var tripForReport:  LifecycleTrip?   // "View Report" → TripReportView

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Trips")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Track and manage your trips")
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
                    .background(Color(UIColor.systemGroupedBackground))

                    // ── Trip card list ────────────────────────────────────
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredTrips) { trip in
                                TripCardView(
                                    trip: trip,
                                    onAccept:      { viewModel.acceptTrip(trip) },
                                    onDecline:     { viewModel.declineTrip(trip) },
                                    onStart:       { tripToNavigate = trip },
                                    onViewSummary: { tripForReport  = trip }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarHidden(true)

            // ── "View Trip" → TripDetailView (Trips tab controls enabled) ──
            .navigationDestination(isPresented: Binding(
                get: { tripToNavigate != nil },
                set: { if !$0 { tripToNavigate = nil } }
            )) {
                if let selected = tripToNavigate {
                    TripDetailView(
                        trip: selected.toTripModel(),
                        showTripControls: true,
                        lifecycleTrip: selected,         // forwarded to ReportIssueView
                        onTripEnded: {
                            viewModel.endTrip(selected.id)
                        }
                    )
                }
            }

            // ── "View Report" → TripReportView ──────────────────────────
            .navigationDestination(isPresented: Binding(
                get: { tripForReport != nil },
                set: { if !$0 { tripForReport = nil } }
            )) {
                if let selected = tripForReport {
                    TripReportView(trip: selected)
                }
            }
        }
    }
}

#Preview {
    TripsView()
}
