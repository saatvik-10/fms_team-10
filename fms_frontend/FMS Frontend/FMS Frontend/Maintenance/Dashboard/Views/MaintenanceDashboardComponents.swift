//
//  MaintenanceDashboardComponents.swift
//  FMS Frontend
//
//  Reusable sub-views for the Maintenance Dashboard.
//  Follows iOS HIG native design guidelines.
//

import SwiftUI

// MARK: - Fleet Analysis Card
/// KPI card for Fleet Analysis in a 2-column grid.
struct FleetAnalysisCard: View {
    let title: String
    let count: String
    let color: Color
    var showsChevron: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(count)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            Group {
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(.systemGray4))
                        .padding(16)
                }
            },
            alignment: .topTrailing
        )
    }
}

// MARK: - Summary Card
/// KPI card for Critical Alerts and Pending Orders in a 2-column grid.
struct SummaryCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(count)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.primaryText.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Dashboard Long Pill
/// Full-width KPI pill with value, title, and chevron.
struct DashboardLongPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var emphasize: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(emphasize ? color.opacity(0.45) : Color.clear, lineWidth: emphasize ? 1.5 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dashboard Section Header
/// Reusable section header with title and optional navigation chevron.
struct MaintenanceSectionHeader<Destination: View>: View {
    let title: String
    let destination: Destination

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Spacer()
            NavigationLink(destination: destination) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
    }
}

// MARK: - Maintenance Alert Card
struct MaintenanceDashboardAlertCard: View {
    let item: DashboardAlertItem

    private let iconName = "exclamationmark.triangle.fill"
    private let iconColor: Color = .red

    var body: some View {
        HStack(spacing: 14) {
            // Left Icon in circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            // Title + Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                Text(item.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// MARK: - Issue Report Card
struct IssueReportTaskCard: View {
    let report: MaintenanceIssueReportItem

    private func statusColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "RESOLVED": return .green
        case "OPEN": return .red
        default: return .blue
        }
    }

    private var titleText: String {
        let summary = report.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if summary.isEmpty { return report.vehicleUnit }
        return String(summary.prefix(48))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .frame(width: 48, height: 48)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(titleText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(report.vehicleUnit) • \(report.incidentLocation)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            HStack(spacing: 0) {
                MetadataCell(icon: "calendar", text: report.createdAt.formatted(.dateTime.day().month(.abbreviated)))

                Divider().frame(height: 16)

                HStack(spacing: 6) {
                    Text(report.status.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(report.status).opacity(0.12))
                        .foregroundColor(statusColor(report.status))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}


// MARK: - Dashboard Empty State Card
/// Shown when a dashboard section has no data to display.
struct MaintenanceEmptyCard: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
