import SwiftUI

struct FleetManagerDriversListView: View {
    @State private var searchText = ""
    @State private var showingAddDriver = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(spacing: 20) {
                Text("DRIVERS MANAGEMENT")
                    .font(.system(size: 20, weight: .black))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name, license or status...", text: $searchText)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 400)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.gray)
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.gray)
                    
                    Button(action: { showingAddDriver = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Driver")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(25)
            .background(Color.white)
            
            // MARK: - Table
            ScrollView {
                VStack(spacing: 0) {
                    // Column Headers
                    HStack {
                        Text("DRIVER IDENTITY").frame(width: 250, alignment: .leading)
                        Text("LICENSE DETAILS").frame(width: 200, alignment: .leading)
                        Text("STATUS").frame(width: 150, alignment: .leading)
                        Spacer()
                        Text("RATING").frame(width: 150, alignment: .trailing)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(MockDataProvider.drivers) { driver in
                            NavigationLink(destination: DriverDetailView(driver: driver)) {
                                DriverRowView(driver: driver)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Register New Asset Dotted Box
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("REGISTER NEW ASSET")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundColor(Color.gray.opacity(0.3))
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(AppTheme.background)
            
            // MARK: - Footer
            HStack {
                HStack(spacing: 40) {
                    FooterStat(label: "TOTAL ASSETS", value: "1,240 DRIVERS")
                    FooterStat(label: "CURRENT UTILIZATION", value: "84.2%")
                    FooterStat(label: "FLEET HEALTH", value: "OPTIMAL", valueColor: AppTheme.activeGreen)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Text("EXPORT REPORT")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                    }
                    .foregroundColor(.black)
                    
                    Button(action: {}) {
                        Text("FULL AUDIT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddDriver) { DriverModalView() }
    }
}

struct DriverRowView: View {
    let driver: Driver
    
    var body: some View {
        HStack {
            // Identity
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 45, height: 45)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.name)
                        .font(.system(size: 15, weight: .bold))
                    Text("ID: \(driver.id)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 250, alignment: .leading)
            
            // License
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.licenseNum)
                    .font(.system(size: 14, weight: .medium))
                Text("Exp: \(driver.licenseExp)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .frame(width: 200, alignment: .leading)
            
            // Status
            Text(driver.status.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(driver.status == .active ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(driver.status == .active ? Color.black : Color.gray.opacity(0.1))
                .cornerRadius(12)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            // Rating
            HStack(spacing: 4) {
                Text(String(format: "%.2f", driver.rating))
                    .font(.system(size: 15, weight: .bold))
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal, 30)
    }
}

struct FooterStat: View {
    let label: String
    let value: String
    var valueColor: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(valueColor)
        }
    }
}
