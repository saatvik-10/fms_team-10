//
//  MaintenanceDashboardComponents.swift
//  FMS Frontend
//
//  Reusable sub-views for the Maintenance Dashboard.
//  Follows iOS HIG native design guidelines.
//

import SwiftUI

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
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
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

// MARK: - Low Stock Card
/// Full-width banner card showing count of parts that need restocking.
struct LowStockCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Low Stock Parts")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                Text("\(count) part\(count == 1 ? "" : "s") need restocking")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray4))
                .padding(.leading, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
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

// MARK: - Priority Feed Card
/// Card showing a single high-priority work order in the Priority Feed.
struct PriorityFeedCard: View {
    let item: PriorityFeedItem

    private var priorityColor: Color {
        switch item.priority {
        case .critical: return AppColors.priorityCritical
        case .high:     return AppColors.priorityHigh
        case .medium:   return AppColors.priorityMedium
        case .low:      return AppColors.priorityLow
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Priority stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(priorityColor)
                .frame(width: 4, height: 46)

            // Icon
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
                .frame(width: 42, height: 42)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            // Title + Vehicle
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(item.vehicleName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Priority badge + chevron
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.priority.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.12))
                    .foregroundColor(priorityColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}


// MARK: - Inspection Summary Card
/// Custom card for Daily Inspections showing Done vs Total in a clear layout.
struct InspectionSummaryCard: View {
    let completed: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 36, height: 36)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(completed)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    Text("Done")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.bottom, 4)
                }
                
                Text("\(total) Total Inspections")
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

// MARK: - Active Staff Row
/// Single row showing a technician and the vehicle they are working on.
struct ActiveStaffRow: View {
    let staff: ActiveStaffItem

    /// Derives 1–2 uppercase initials from the technicianId.
    private var initials: String {
        let parts   = staff.technicianId.components(separatedBy: CharacterSet(charactersIn: "-_ "))
        let letters = parts.compactMap { $0.first }.prefix(2)
        let built   = letters.map(String.init).joined().uppercased()
        return built.isEmpty ? "TN" : built
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }

            // Technician info FIRST
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.technicianId)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                HStack(spacing: 4) {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(staff.vehicleName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("IN PROGRESS")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
