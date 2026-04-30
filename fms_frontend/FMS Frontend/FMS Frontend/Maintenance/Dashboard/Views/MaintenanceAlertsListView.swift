//
//  MaintenanceAlertsListView.swift
//  FMS Frontend
//
//  Dashboard-only detail screen for driver-generated maintenance alerts.
//  Accessible only through the dashboard chevron.
//

import SwiftUI

struct MaintenanceAlertsListView: View {
    @EnvironmentObject var store: MaintenanceStore

    private var issueReports: [MaintenanceIssueReportItem] {
        store.issueReports
            .filter { $0.tripId != nil && !($0.tripId?.isEmpty ?? true) }
            .sorted {
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt > $1.createdAt
                }
                return $0.transcript.localizedCaseInsensitiveCompare($1.transcript) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if issueReports.isEmpty {
                    MaintenanceEmptyCard(message: "No maintenance alerts", icon: "checkmark.circle.fill")
                        .padding(.top, 8)
                } else {
                    ForEach(issueReports, id: \.id) { report in
                        NavigationLink(destination: IssueReportDetailView(report: report)) {
                            IssueReportTaskCard(report: report)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Maintenance Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IssueReportDetailView: View {
    let report: MaintenanceIssueReportItem

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(report.transcript)
                        .font(.headline)
                        .foregroundColor(AppColors.primaryText)
                    Text(report.vehicleUnit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.primary)
                    Text(report.incidentLocation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Report Details") {
                detailRow("Report ID", report.id)
                detailRow("Driver User ID", report.driverUserId)
                detailRow("Trip ID", report.tripId ?? "Not linked")
                detailRow("Status", report.status)
                detailRow("Created At", Self.formatter.string(from: report.createdAt))
                detailRow("Updated At", Self.formatter.string(from: report.updatedAt))
            }

            Section("Submission Fields") {
                detailRow("Transcript", report.transcript)
                detailRow("Incident Location", report.incidentLocation)
                detailRow("Vehicle Unit", report.vehicleUnit)
                detailRow("Image Keys", report.imageKeys.isEmpty ? "None" : report.imageKeys.joined(separator: ", "))
            }

            Section("Images") {
                if let imageUrls = report.imageUrls, !imageUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(imageUrls, id: \.self) { urlString in
                                AsyncImage(url: URL(string: urlString)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 110, height: 110)
                                            .background(Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(14)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipped()
                                            .cornerRadius(14)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 22))
                                            .frame(width: 110, height: 110)
                                            .background(Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(14)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("No images attached")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Issue Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(AppColors.primaryText)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}
