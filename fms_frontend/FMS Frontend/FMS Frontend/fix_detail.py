path = "./FleetManager/VehicleManagement/Views/FleetManagerVehicleDetailView.swift"
with open(path, "r") as f:
    cv = f.read()

# Fix Assessment Insight padding: remove the outer `.padding(.horizontal, 40)` which squishes it
old_insight = """                            .background(AppTheme.primary.opacity(0.03))
                            .cornerRadius(20)
                            .padding(.horizontal, 40)"""
new_insight = """                            .background(AppTheme.primary.opacity(0.03))
                            .cornerRadius(20)"""
cv = cv.replace(old_insight, new_insight)

# Find where "if let trip = vehicle.currentTrip {" occurs
# We want to add an `else` branch.
old_transit = """                            // Current Transit
                            if let trip = vehicle.currentTrip {
                                VStack(alignment: .leading, spacing: 35) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("CURRENT TRANSIT")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text("Active Trip")
                                                .font(.system(size: 24, weight: .bold))
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("ETA")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.eta)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }
                                    
                                    // Origin -> Destination Progress
                                    HStack(spacing: 30) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(AppTheme.primary)
                                                .frame(width: 32, height: 32)
                                                .overlay(Image(systemName: "arrow.right").foregroundColor(.white).font(.system(size: 12)))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("ORIGIN")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text(trip.origin)
                                                    .font(.system(size: 18, weight: .black))
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        // Progress Bar
                                        ZStack {
                                            Capsule()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 12)
                                            
                                            Capsule()
                                                .fill(AppTheme.primary)
                                                .frame(width: 100, height: 12)
                                                .overlay(
                                                    Text("\(Int(trip.progress * 100))%")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        HStack(spacing: 12) {
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("DESTINATION")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text(trip.destination)
                                                    .font(.system(size: 18, weight: .black))
                                                    .lineLimit(1)
                                            }
                                            
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                                .overlay(Image(systemName: "mappin").foregroundColor(.gray).font(.system(size: 12)))
                                        }
                                    }
                                }
                                .padding(40)
                                .background(Color.white)
                                .cornerRadius(20)
                            }"""

new_transit = """                            // Current Transit
                            VStack(alignment: .leading, spacing: 35) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("CURRENT TRANSIT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.gray)
                                        Text(vehicle.currentTrip != nil ? "Active Trip" : "No Active Journey")
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                    Spacer()
                                    if let trip = vehicle.currentTrip {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("ETA")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.eta)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }
                                }
                                
                                if let trip = vehicle.currentTrip {
                                    // Origin -> Destination Progress
                                    HStack(spacing: 30) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(AppTheme.primary)
                                                .frame(width: 32, height: 32)
                                                .overlay(Image(systemName: "arrow.right").foregroundColor(.white).font(.system(size: 12)))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("ORIGIN")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text(trip.origin)
                                                    .font(.system(size: 18, weight: .black))
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        // Progress Bar
                                        ZStack {
                                            Capsule()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 12)
                                            
                                            Capsule()
                                                .fill(AppTheme.primary)
                                                .frame(width: 100, height: 12)
                                                .overlay(
                                                    Text("\\(Int(trip.progress * 100))%")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        HStack(spacing: 12) {
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("DESTINATION")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text(trip.destination)
                                                    .font(.system(size: 18, weight: .black))
                                                    .lineLimit(1)
                                            }
                                            
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                                .overlay(Image(systemName: "mappin").foregroundColor(.gray).font(.system(size: 12)))
                                        }
                                    }
                                } else {
                                    HStack {
                                        Spacer()
                                        Text("Vehicle is currently idle")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                }
                                Spacer()
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white)
                            .cornerRadius(20)"""
cv = cv.replace(old_transit, new_transit)

# Fix Assigned Driver cell height matching
old_drv = """.padding(40)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }"""
new_drv = """.padding(40)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }
                        .frame(height: 250) // Balance out the container max height"""

if old_drv in cv:
    cv = cv.replace(old_drv, new_drv)
# But wait, old_drv must match exactly.
with open(path, "w") as f:
    f.write(cv)
