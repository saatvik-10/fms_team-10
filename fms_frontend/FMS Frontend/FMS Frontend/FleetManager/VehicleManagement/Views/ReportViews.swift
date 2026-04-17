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
                .foregroundColor(.black)
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
                    
                    VStack(spacing: 15) {
                        ForEach(vehicle.reports) { report in
                            NavigationLink(destination: MaintenanceReportDetailView(report: report, vehicle: vehicle)) {
                                HStack(spacing: 20) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12).fill(AppTheme.criticalRed.opacity(0.1))
                                            .frame(width: 55, height: 55)
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.criticalRed)
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
                                .modifier(AppTheme.cardShadow())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Maintenance Report Detail (Simulated PDF)
struct MaintenanceReportDetailView: View {
    let report: VehicleReport
    let vehicle: Vehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.black)
                Spacer()
                Text("DOCUMENT PREVIEW")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button(action: { }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.black)
                }
            }
            .padding(25)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 30) {
                    // The "PDF" Page
                    VStack(alignment: .leading, spacing: 40) {
                        // Document Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(report.serviceProvider.uppercased())
                                    .font(.system(size: 20, weight: .black))
                                Text("Automotive Service & Fleet Maintenance")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text("License #FMS-99203-A")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 10) {
                                Text("MAINTENANCE REPORT")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.criticalRed)
                                Text("Date: \(report.date)")
                                    .font(.system(size: 12))
                                Text("Ref: #\(UUID().uuidString.prefix(8).uppercased())")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Divider()
                        
                        // Vehicle Info Section
                        HStack(spacing: 50) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("VEHICLE IDENTITY")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(vehicle.id)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("VIN NUMBER")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("4G2BM5...")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ODOMETER")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("\(vehicle.odometer) MI")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        
                        // Tasks Performed
                        VStack(alignment: .leading, spacing: 20) {
                            Text("SERVICES PERFORMED")
                                .font(.system(size: 12, weight: .black))
                                .padding(.bottom, 10)
                                .overlay(Rectangle().frame(height: 2).offset(y: 10), alignment: .bottom)
                            
                            ForEach(report.tasks) { task in
                                HStack {
                                    Text(task.description)
                                        .font(.system(size: 14))
                                    Spacer()
                                    Text(task.cost)
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .padding(.vertical, 5)
                                Divider()
                            }
                        }
                        
                        // Total Cost
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 10) {
                                Text("TOTAL COST")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(report.totalCost)
                                    .font(.system(size: 32, weight: .black))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Footer / Signature
                        VStack(alignment: .leading, spacing: 15) {
                            Text("CERTIFICATION")
                                .font(.system(size: 10, weight: .bold))
                            Text("I hereby certify that the above mentioned services were performed and parts replaced as described in accordance with fleet safety standards.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Rectangle().frame(width: 200, height: 1)
                                    Text("Technician Signature")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 40))
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(50)
                    .background(Color.white)
                    .cornerRadius(2)
                    .modifier(AppTheme.cardShadow())
                    .padding(40)
                    
                }
            }
            .background(Color.gray.opacity(0.1))
        }
        .navigationBarHidden(true)
    }
}
