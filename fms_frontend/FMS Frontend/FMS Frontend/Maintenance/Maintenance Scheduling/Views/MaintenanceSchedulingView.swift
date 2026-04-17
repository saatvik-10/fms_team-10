//
//  MaintenanceSchedulingView.swift
//  FMS Frontend
//

import SwiftUI
import UIKit

// MARK: - UICalendarView Wrapper
struct NativeCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedDate: $selectedDate)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        calendarView.tintColor = UIColor(AppColors.primary)
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Pre-select today
        let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        (calendarView.selectionBehavior as? UICalendarSelectionSingleDate)?.setSelected(components, animated: false)

        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {}

    class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        @Binding var selectedDate: Date

        init(selectedDate: Binding<Date>) {
            _selectedDate = selectedDate
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dc = dateComponents,
                  let date = Calendar.current.date(from: dc) else { return }
            // Preserve existing time components
            let existing = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
            var merged = dc
            merged.hour = existing.hour ?? 0
            merged.minute = existing.minute ?? 0
            selectedDate = Calendar.current.date(from: merged) ?? date
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            true
        }
    }
}

// MARK: - Scheduling View
struct MaintenanceSchedulingView: View {
    @StateObject private var viewModel: MaintenanceSchedulingViewModel
    @Environment(\.presentationMode) var presentationMode

    init(vehicleId: String? = nil, description: String? = nil) {
        _viewModel = StateObject(wrappedValue: MaintenanceSchedulingViewModel(vehicleId: vehicleId, description: description))
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // ── Form fields ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SCHEDULE MAINTENANCE")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            // Vehicle ID
                            HStack(spacing: 12) {
                                Image(systemName: "car.side.fill")
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                    .frame(width: 24)
                                TextField("Vehicle ID (e.g. V-101)", text: $viewModel.selectedVehicleId)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(16)

                            Divider().padding(.leading, 52)

                            // Issue description
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Issue Description", systemImage: "text.alignleft")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))

                                TextEditor(text: $viewModel.issueDescription)
                                    .frame(height: 90)
                                    .padding(10)
                                    .background(AppColors.screenBackground)
                                    .cornerRadius(10)
                            }
                            .padding(16)

                            Divider().padding(.leading, 16)

                            // Priority
                            HStack {
                                Label("Priority", systemImage: "flag.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                Spacer()
                                Picker("Priority", selection: $viewModel.selectedPriority) {
                                    ForEach(MaintenancePriority.allCases, id: \.self) { p in
                                        Text(p.rawValue).tag(p)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(AppColors.primary)
                            }
                            .padding(16)
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    }

                    // ── Full Calendar ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT DATE & TIME")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            NativeCalendarView(selectedDate: $viewModel.scheduledDate)
                                .padding(.horizontal, 8)
                                .padding(.top, 8)

                            Divider().padding(.horizontal)

                            // Time picker
                            HStack {
                                Label("Time", systemImage: "clock")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $viewModel.scheduledDate,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            .padding(16)
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    }

                    // Confirm button
                    PrimaryButton(title: "Confirm Schedule") {
                        viewModel.scheduleMaintenance()
                        presentationMode.wrappedValue.dismiss()
                    }

                    // ── Active Schedules ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVE SCHEDULES")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)

                        if viewModel.schedules.isEmpty {
                            Text("No active schedules")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.schedules) { schedule in
                                    ScheduleRow(schedule: schedule)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Scheduling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Schedule Row
struct ScheduleRow: View {
    let schedule: MaintenanceSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16, weight: .bold))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(schedule.vehicleId)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        Text(schedule.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }

                Spacer()

                StatusBadge(text: schedule.priority.rawValue, color: priorityColor(schedule.priority))
            }

            Text(schedule.reportedIssue)
                .font(.system(size: 15))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    func priorityColor(_ priority: MaintenancePriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct MaintenanceSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceSchedulingView()
        }
    }
}
