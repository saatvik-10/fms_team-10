import SwiftUI
import MapKit

struct DriverDetailView: View {
    let driver: Driver
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(spacing: 20) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .bold))
                }
                
                Text("DRIVERS MANAGEMENT")
                    .font(.system(size: 14, weight: .black))
                
                Spacer()
                
                HStack(spacing: 20) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search drivers...")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Image(systemName: "bell.fill")
                    Image(systemName: "questionmark.circle.fill")
                    
                    Button("Add Driver") { }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(6)
                }
                .foregroundColor(.gray)
            }
            .padding(25)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: - Profile Section
                    HStack(spacing: 30) {
                        // Profile Image
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                )
                            
                            Circle()
                                .fill(AppTheme.activeGreen)
                                .frame(width: 25, height: 25)
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(driver.name)
                                .font(.system(size: 38, weight: .black))
                            
                            Text(driver.title.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Button(action: {}) {
                                    Label("Call", systemImage: "phone.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.black)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {}) {
                                    Label("Message", systemImage: "message.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.gray)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 40) {
                            DetailHeaderStat(label: "STATUS", value: driver.status.rawValue, color: AppTheme.activeGreen)
                            DetailHeaderStat(label: "EFFICIENCY", value: driver.efficiency)
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // MARK: - Grid of Stats & Rating
                    HStack(alignment: .top, spacing: 25) {
                        // Left Column: Small Stats Cards
                        VStack(spacing: 25) {
                            HStack(spacing: 25) {
                                MiniStatCard(label: "LICENSE NO.", value: driver.licenseNum)
                                MiniStatCard(label: "EXPIRY DATE", value: driver.licenseExp)
                            }
                            
                            HStack(spacing: 25) {
                                MiniStatCard(label: "TOTAL TRIPS", value: "\(driver.totalTrips)", trend: "+12 this month", trendColor: AppTheme.activeGreen)
                                MiniStatCard(label: "TOTAL HOURS", value: "\(driver.totalHours)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column: Rating Card
                        RatingCard(rating: driver.rating)
                            .frame(width: 350)
                    }
                    
                    // MARK: - Current Assignment & Activity Log
                    HStack(alignment: .top, spacing: 25) {
                        // Left: Map Card
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("CURRENT ASSIGNMENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            
                            Text("Vehicle ID: VX-7702")
                                .font(.system(size: 16, weight: .bold))
                            
                            // Native Map Component
                            MapComponentView()
                                .frame(height: 250)
                                .cornerRadius(12)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ACTIVE ROUTE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("IH-35 North bound")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("ETA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("14:20 (22 mins)")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        // Right: Activity Log
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("RECENT ACTIVITY LOG")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("View All")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            
                            VStack(spacing: 20) {
                                ForEach(driver.activityLog) { event in
                                    ActivityRow(event: event)
                                }
                            }
                        }
                        .padding(25)
                        .frame(width: 400)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                }
                .padding(30)
                .padding(.bottom, 50)
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subcomponents

struct DetailHeaderStat: View {
    let label: String
    let value: String
    var color: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(color)
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    var trend: String? = nil
    var trendColor: Color = .gray
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            HStack(alignment: .bottom) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trendColor)
                        .padding(.bottom, 4)
                }
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct RatingCard: View {
    let rating: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("RATING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.yellow)
            }
            
            HStack(alignment: .center, spacing: 20) {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 60, weight: .black))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in Image(systemName: "star.fill").font(.system(size: 12)) }
                    }
                    .foregroundColor(.yellow)
                    
                    Text("Based on 412 reviews")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 12) {
                RatingRow(label: "SAFETY", progress: 0.9)
                RatingRow(label: "SPEED", progress: 0.8)
                RatingRow(label: "LOGIST.", progress: 0.95)
            }
        }
        .padding(30)
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(16)
    }
}

struct RatingRow: View {
    let label: String
    let progress: CGFloat
    
    var body: some View {
        HStack(spacing: 15) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.3)).frame(height: 4)
                    Capsule().fill(Color.white).frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct ActivityRow: View {
    let event: ActivityEvent
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                Text(event.detail + " • " + event.time)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let val = event.value {
                Text(val)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(event.type == "incident" ? AppTheme.criticalRed : .gray)
            }
        }
    }
    
    var iconName: String {
        switch event.type {
        case "completed": return "checkmark.circle.fill"
        case "refueling": return "fuelpump.fill"
        case "started": return "clock.arrow.2.circlepath"
        case "incident": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Native Map Simulation
struct MapComponentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))]) { point in
            MapAnnotation(coordinate: point.coordinate) {
                Image(systemName: "truck.box.fill")
                    .padding(8)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .disabled(true) // Static look as per Image 3
    }
}

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
