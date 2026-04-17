path = "./FleetManager/DriverVehicleAssignment/Views/FleetManagerDriversListView.swift"
with open(path, "r") as f:
    df = f.read()

df = df.replace('Text("DRIVERS MANAGEMENT")', 'Text("Drivers Management")')

with open(path, "w") as f:
    f.write(df)
