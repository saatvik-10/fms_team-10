# 1. Modals.swift cost logic
path_modals = "./FleetManager/Resources/Modals.swift"
with open(path_modals, "r") as f:
    mf = f.read()

old_cost = """    // Dynamic estimation logic
    private var estimatedCost: Double {
        let length = Double(fromLocation.count + toLocation.count)
        return max(75.50, length * 8.25)
    }
    
    private var estimatedDistance: Int {
        return max(45, (fromLocation.count + toLocation.count) * 12)
    }"""
new_cost = """    // Dynamic estimation logic
    private var estimatedDistance: Int {
        if fromLocation.isEmpty && toLocation.isEmpty { return 0 }
        return max(45, (fromLocation.count + toLocation.count) * 12)
    }
    
    private var estimatedCost: Double {
        if estimatedDistance == 0 { return 0.0 }
        return max(75.50, Double(estimatedDistance) * 1.5 + 25.0)
    }"""

mf = mf.replace(old_cost, new_cost)
with open(path_modals, "w") as f:
    f.write(mf)


# 2. Driver Management tweaks
path_drivers = "./FleetManager/DriverVehicleAssignment/Views/FleetManagerDriversListView.swift"
with open(path_drivers, "r") as f:
    df = f.read()

# Change title
df = df.replace('Text("Drivers Management")', 'Text("Drivers")')

# Shift Search Bar to left: It is currently a Spacer, then HStack Search Bar. Let's make it sit next to title.
# Wait, let's fix the row first.
old_row = """            // Status
            Text(driver.status.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(driver.status == .active ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(driver.status == .active ? AppTheme.primary : Color.gray.opacity(0.1))
                .cornerRadius(12)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            // Action Menu
            Image(systemName: "ellipsis")
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .trailing)"""
new_row = """            Spacer()
            // Status
            Text(driver.status.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(driver.status == .active ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(driver.status == .active ? AppTheme.primary : Color.gray.opacity(0.1))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: .trailing)"""

df = df.replace(old_row, new_row)
with open(path_drivers, "w") as f:
    f.write(df)


# 3. Add heading to CO2 Graph & fix Dashboard trends
path_dashboard = "./FleetManager/Dashboard/Views/FleetManagerDashboardView.swift"
with open(path_dashboard, "r") as f:
    dbf = f.read()

# Add CO2 heading
old_co2 = """                        // MARK: - CO2 Emissions
                        FleetOpsEmissionsChart(data: dataManager.emissionData)"""
new_co2 = """                        // MARK: - CO2 Emissions
                        VStack(alignment: .leading, spacing: 20) {
                            Text("CO2 Emissions Tracker")
                                .font(.system(size: 18, weight: .bold))
                            FleetOpsEmissionsChart(data: dataManager.emissionData)
                        }"""
if old_co2 in dbf:
    dbf = dbf.replace(old_co2, new_co2)

with open(path_dashboard, "w") as f:
    f.write(dbf)
