path = "./FleetManager/VehicleManagement/Views/FleetManagerVehicleDetailView.swift"
with open(path, "r") as f:
    cv = f.read()

# Fix History Empty State
old_hist = """                                VStack(spacing: 0) {
                                    ForEach(vehicle.history) { trip in"""
new_hist = """                                VStack(spacing: 0) {
                                    if vehicle.history.isEmpty {
                                        Text("No history yet")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 20)
                                    } else {
                                    ForEach(vehicle.history) { trip in"""

cv = cv.replace(old_hist, new_hist)

# Fix brace matching for History block
old_hist_close = """                                    }
                                }
                                
                                NavigationLink(destination: VehicleLogView(vehicle: vehicle)) {"""

new_hist_close = """                                    }
                                    }
                                }
                                
                                NavigationLink(destination: VehicleLogView(vehicle: vehicle)) {"""
cv = cv.replace(old_hist_close, new_hist_close)


# Fix Reports Empty State
old_rep = """                            HStack(spacing: 20) {
                                ForEach(vehicle.reports) { report in"""
new_rep = """                            if vehicle.reports.isEmpty {
                                Text("No reports yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 20)
                            } else {
                            HStack(spacing: 20) {
                                ForEach(vehicle.reports) { report in"""

cv = cv.replace(old_rep, new_rep)

# Fix brace matching for Reports block
old_rep_close = """                                }
                            }
                            
                            NavigationLink(destination: ArchiveListView(vehicle: vehicle)) {"""

new_rep_close = """                                }
                            }
                            }
                            
                            NavigationLink(destination: ArchiveListView(vehicle: vehicle)) {"""

cv = cv.replace(old_rep_close, new_rep_close)

with open(path, "w") as f:
    f.write(cv)

# Now fix ArchiveListView inside ReportViews.swift
path_rep = "./FleetManager/VehicleManagement/Views/ReportViews.swift"
with open(path_rep, "r") as f:
    rv = f.read()

old_archive = """                    VStack(spacing: 15) {
                        ForEach(vehicle.reports) { report in"""

new_archive = """                    if vehicle.reports.isEmpty {
                        Text("No history yet")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                    VStack(spacing: 15) {
                        ForEach(vehicle.reports) { report in"""

if old_archive in rv:
    rv = rv.replace(old_archive, new_archive)
    
    old_a_close = """                        }
                    }
                    .padding(.horizontal, 30)"""
    new_a_close = """                        }
                    }
                    }
                    .padding(.horizontal, 30)"""
    rv = rv.replace(old_a_close, new_a_close)

with open(path_rep, "w") as f:
    f.write(rv)
