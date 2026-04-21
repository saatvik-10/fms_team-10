import SwiftUI

// MARK: - Archive List View
struct ArchiveListView: View {
    let vehicle: Vehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(AppColors.primary)
                Spacer()
                Text("REPORTS ARCHIVE")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Image(systemName: "magnifyingglass")
            }
            .padding(25)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(vehicle.id) RECORDS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        Text("Past Reports Archive")
                            .font(.system(size: 32, weight: .black))
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        if vehicle.reports.isEmpty {
                            Text("No history yet")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(vehicle.reports) { report in
                                NavigationLink(destination: MaintenanceReportDetailView(report: report, vehicle: vehicle)) {
                                    HStack(spacing: 20) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12).fill(AppColors.criticalRed.opacity(0.1))
                                                .frame(width: 55, height: 55)
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppColors.criticalRed)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(report.title)
                                                .font(.system(size: 18, weight: .bold))
                                            Text(report.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.3))
                                    }
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .modifier(AppColors.cardShadow())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
    }
}


// MARK: - Maintenance Requests List

struct MaintenanceReportBundle: Identifiable {
    var id: UUID { report.id }
    let vehicle: Vehicle
    let report: VehicleReport
}
struct MaintenanceRequestsListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var actionedRequests: Set<UUID> = []
    
    var requests: [MaintenanceReportBundle] {
        dataManager.vehicles.flatMap { v in v.reports.map { MaintenanceReportBundle(vehicle: v, report: $0) } }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(AppColors.primary)
                        Spacer()
                        Text("MAINTENANCE REQUESTS").font(.system(size: 14, weight: .bold))
                        Spacer()
                        
                    }
                    .padding(25)
                    .background(Color.white)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(requests) { bundle in
                                let vehicle = bundle.vehicle
                                let report = bundle.report
                                
                                VStack(spacing: 20) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(vehicle.id).font(.system(size: 18, weight: .black))
                                            Text(report.date).font(.system(size: 12)).foregroundColor(.gray)
                                        }
                                        Spacer()
                                        NavigationLink(destination: MaintenanceReportDetailView(report: report, vehicle: vehicle)) {
                                            Text("View Assessment")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(AppColors.primary.opacity(0.1))
                                                .cornerRadius(20)
                                        }
                                    }
                                    
                                    if actionedRequests.contains(report.id) {
                                        HStack {
                                            Spacer()
                                            Text("Processed")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.gray)
                                            Spacer()
                                        }
                                    } else {
                                        HStack(spacing: 15) {
                                            Button(action: { actionedRequests.insert(report.id) }) {
                                                Text("Disapprove")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .foregroundColor(.white)
                                                    .background(AppColors.criticalRed)
                                                    .cornerRadius(8)
                                            }
                                            Button(action: { actionedRequests.insert(report.id) }) {
                                                Text("Approve")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .foregroundColor(.white)
                                                    .background(AppColors.activeGreen)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(12)
                                .modifier(AppColors.cardShadow())
                            }
                        }
                        .padding(30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Maintenance Report Detail (Simulated PDF matching Screenshot)
struct MaintenanceReportDetailView: View {
    let report: VehicleReport
    let vehicle: Vehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Action Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                    Text("InspectionReport_\(vehicle.id)")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                Spacer()
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Page Indicator header
                    HStack {
                        Text("Fleet Management System — Confidential")
                            .font(.system(size: 10))
                        Spacer()
                        Text("Page 1")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    
                    // PDF Core Document Main Layout
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // Dark Blue Top Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FLEET MANAGEMENT SYSTEM")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.white)
                            Text("Vehicle Inspection Report")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.04, green: 0.19, blue: 0.23)) // #0a303a AppColors.primary
                        
                        VStack(alignment: .leading, spacing: 25) {
                            
                            // Section: VEHICLE INFORMATION
                            VStack(alignment: .leading, spacing: 10) {
                                PdfSectionHeader(title: "VEHICLE INFORMATION")
                                PdfRow(label: "Vehicle", value: "\(vehicle.make) \(vehicle.model) (\(vehicle.type))", isZebra: false)
                                PdfRow(label: "VIN", value: "VIN-5930", isZebra: true)
                                PdfRow(label: "Type", value: vehicle.type, isZebra: false)
                                PdfRow(label: "Inspection", value: "Pre-Trip", isZebra: true)
                                PdfRow(label: "Date", value: report.date, isZebra: false)
                                PdfRow(label: "Inspector ID", value: "STAFF-01", isZebra: true)
                                PdfRow(label: "Driver ID", value: "DRV-CURRENT", isZebra: false)
                                PdfRow(label: "Status", value: "Pending", isZebra: true)
                            }
                            
                            // Section: VEHICLE METRICS
                            VStack(alignment: .leading, spacing: 10) {
                                PdfSectionHeader(title: "VEHICLE METRICS")
                                PdfRow(label: "Odometer", value: "\(vehicle.odometer) mi", isZebra: false)
                                PdfRow(label: "Fuel Level", value: "75%", isZebra: true)
                                PdfRow(label: "Fuel Effic.", value: "14.2 mpg", isZebra: false)
                                PdfRow(label: "Engine Hours", value: "4,821 hrs", isZebra: true)
                            }
                            
                            // Section: INSPECTION SUMMARY
                            VStack(alignment: .leading, spacing: 10) {
                                PdfSectionHeader(title: "INSPECTION SUMMARY")
                                PdfRow(label: "Total Items", value: "13", isZebra: false)
                                PdfRow(label: "Good", value: "9", isZebra: true)
                                PdfRow(label: "Repair Needed", value: "0", isZebra: false)
                                PdfRow(label: "Alert", value: "0", isZebra: true)
                                PdfRow(label: "Pending", value: "4", isZebra: false)
                                PdfRow(label: "Total Cost", value: "₹ \(report.totalCost.replacingOccurrences(of: "$", with: ""))", isZebra: true)
                                
                                HStack {
                                    Text("✓ PASS")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppColors.activeGreen)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.activeGreen.opacity(0.1))
                            }
                            
                            Spacer().frame(height: 50)
                            
                            // Segment 2: Checklist Header
                            Text("INSPECTION CHECKLIST")
                                .font(.system(size: 18, weight: .black))
                            
                            // Checklist Table Headers
                            HStack {
                                Text("Inspection Item").bold().frame(width: 180, alignment: .leading)
                                Text("Result").bold().frame(width: 80, alignment: .leading)
                                Text("Notes").bold().frame(width: 80, alignment: .leading)
                                Text("Photo").bold().frame(width: 80, alignment: .leading)
                            }
                            .font(.system(size: 10))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            
                            // Table Content Rows
                            VStack(spacing: 0) {
                                PdfChecklistRow(item: "Brakes & Braking System", result: "GOOD", isGood: true, hasPhoto: true, isZebra: false)
                                PdfChecklistRow(item: "Tyres & Wheels", result: "PENDING", isGood: false, hasPhoto: false, isZebra: true)
                                PdfChecklistRow(item: "Engine Oil & Fluid Levels", result: "GOOD", isGood: true, hasPhoto: false, isZebra: false)
                                PdfChecklistRow(item: "Lighting & Electrical", result: "GOOD", isGood: true, hasPhoto: false, isZebra: true)
                                PdfChecklistRow(item: "Steering & Suspension", result: "PENDING", isGood: false, hasPhoto: false, isZebra: false)
                                PdfChecklistRow(item: "Seatbelts & Restraints", result: "GOOD", isGood: true, hasPhoto: false, isZebra: true)
                                PdfChecklistRow(item: "Mirrors & Visibility", result: "GOOD", isGood: true, hasPhoto: false, isZebra: false)
                                PdfChecklistRow(item: "Fuel System", result: "PENDING", isGood: false, hasPhoto: false, isZebra: true)
                                PdfChecklistRow(item: "Battery & Charging System", result: "GOOD", isGood: true, hasPhoto: false, isZebra: false)
                            }
                            
                            Spacer().frame(height: 50)
                            
                            // Signatures
                            HStack {
                                HStack {
                                    Text("Inspector Signature:")
                                        .font(.system(size: 10))
                                    Rectangle().frame(width: 100, height: 1).padding(.bottom, -5).foregroundColor(.black)
                                }
                                Spacer()
                                HStack {
                                    Text("Date:")
                                        .font(.system(size: 10))
                                    Rectangle().frame(width: 80, height: 1).padding(.bottom, -5).foregroundColor(.black)
                                }
                            }
                            .padding(.bottom, 30)
                            
                        }
                        .padding(30)
                        
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .modifier(AppColors.cardShadow())
                    .padding(20)
                }
            }
            .background(Color.gray.opacity(0.1))
        }
        .navigationBarHidden(true)
    }
}

struct PdfSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .bold))
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.1))
    }
}

struct PdfRow: View {
    let label: String
    let value: String
    let isZebra: Bool
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 150, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isZebra ? Color.gray.opacity(0.05) : Color.white)
    }
}

struct PdfChecklistRow: View {
    let item: String
    let result: String
    let isGood: Bool
    let hasPhoto: Bool
    let isZebra: Bool
    
    var body: some View {
        HStack {
            Text(item)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 180, alignment: .leading)
            
            Text(result)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isGood ? AppColors.activeGreen : .gray)
                .frame(width: 80, alignment: .leading)
                
            Text("-")
                .font(.system(size: 12))
                .frame(width: 80, alignment: .leading)
                
            if hasPhoto {
                Image(systemName: "photo.fill")
                    .foregroundColor(.gray)
                    .frame(width: 80, alignment: .leading)
            } else {
                Text("-")
                    .font(.system(size: 12))
                    .frame(width: 80, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(isZebra ? Color.gray.opacity(0.05) : Color.white)
    }
}
