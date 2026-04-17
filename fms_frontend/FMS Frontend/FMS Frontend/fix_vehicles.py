path = "./FleetManager/VehicleManagement/Views/FleetManagerVehiclesListView.swift"
with open(path, "r") as f:
    vf = f.read()

# Add state
if "@State private var showingAddVehicle = false" not in vf:
    vf = vf.replace("    @State private var selectedFilter = \"ALL\"", "    @State private var selectedFilter = \"ALL\"\n    @State private var showingAddVehicle = false")

old_header = """            // MARK: - Header
            HStack(spacing: 20) {
                Text("VEHICLES MANAGEMENT")
                    .font(.system(size: 20, weight: .black))
                
                Spacer()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search unique ID, driver, or VIN...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 400)
                
            }
            .padding(30)"""

new_header = """            // MARK: - Header
            HStack(spacing: 20) {
                Text("Vehicles Management")
                    .font(.system(size: 20, weight: .black))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search unique ID, driver, or VIN...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: { showingAddVehicle = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Vehicle")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .cornerRadius(8)
                }
            }
            .padding(30)"""
vf = vf.replace(old_header, new_header)

old_filters = """            // MARK: - Filters
            HStack(spacing: 0) {
                HStack(spacing: 20) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.white : Color.clear)
                                .foregroundColor(selectedFilter == filter ? .black : .gray)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .background(Color.white)"""

new_filters = """            // MARK: - Filters
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter)
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedFilter == filter ? Color.white : Color.clear)
                                .foregroundColor(selectedFilter == filter ? .black : .gray)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .background(Color.white)"""
vf = vf.replace(old_filters, new_filters)

# Add sheet
if ".sheet(" not in vf:
    vf = vf.replace(".navigationBarHidden(true)", ".navigationBarHidden(true)\n        .sheet(isPresented: $showingAddVehicle) { AddVehicleModalView() }")

with open(path, "w") as f:
    f.write(vf)
