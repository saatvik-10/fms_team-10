//
//  CompletedTripDetailSheet.swift
//  Created by Saatvik Madan
//

import SwiftUI

// MARK: - Completed Trip Detail Sheet (Read-Only)
struct CompletedTripDetailSheet: View {
    let trip: VehicleTrip
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.secondaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Status Banner
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.activeGreen.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(AppTheme.activeGreen)
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trip Completed")
                                    .font(AppFonts.title3)
                                    .foregroundColor(AppTheme.primary)
                                    .accessibilityAddTraits(.isHeader)
                                Text(trip.date ?? "Date unavailable")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Cost chip
                            if let cost = trip.costEstimate {
                                VStack(spacing: 2) {
                                    Text(cost)
                                        .font(AppFonts.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.primary)
                                    Text("TRIP COST")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.gray)
                                        .tracking(1)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .modifier(AppTheme.cardShadow())
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Trip completed on \(trip.date ?? "unknown date"). Cost: \(trip.costEstimate ?? "unavailable")")

                        // MARK: - Route Card
                        SectionCard(title: "ROUTE DETAILS", icon: "map.fill") {
                            VStack(spacing: 0) {
                                HistoryDetailRow(icon: "mappin.circle.fill", label: "Origin", value: trip.origin, iconColor: .green)
                                Divider()
                                HistoryDetailRow(icon: "flag.checkered", label: "Destination", value: trip.destination, iconColor: AppTheme.primary)
                                if let dist = trip.distance {
                                    Divider()
                                    HistoryDetailRow(icon: "ruler.fill", label: "Distance", value: dist, iconColor: .orange)
                                }
                                if let dur = trip.duration, !dur.isEmpty {
                                    Divider()
                                    HistoryDetailRow(icon: "clock.fill", label: "Duration", value: dur, iconColor: .purple)
                                }
                            }
                        }

                        // MARK: - Vehicle Card
                        SectionCard(title: "VEHICLE", icon: "truck.box.fill") {
                            VStack(spacing: 0) {
                                HistoryDetailRow(icon: "number", label: "Vehicle ID", value: trip.vehicleID, iconColor: .blue)
                            }
                        }

                        // MARK: - Cargo Card
                        if let product = trip.productType, !product.isEmpty {
                            SectionCard(title: "CARGO", icon: "shippingbox.fill") {
                                VStack(spacing: 0) {
                                    HistoryDetailRow(icon: "cube.box.fill", label: "Product", value: product, iconColor: .orange)
                                    if let load = trip.loadAmount, !load.isEmpty {
                                        Divider()
                                        HistoryDetailRow(icon: "scalemass.fill", label: "Load", value: load, iconColor: .brown)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppFonts.headline)
                        .foregroundColor(AppTheme.primary)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Double tap to close trip details")
                }
            }
        }
    }
}

// MARK: - Section Card Helper
private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.primary.opacity(0.6))
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
            }
            content()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Detail Row Helper
private struct HistoryDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)

            Text(label)
                .font(AppFonts.body)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppTheme.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .frame(minHeight: 44)
    }
}
