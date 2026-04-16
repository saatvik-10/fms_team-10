import os

base_dir = "/Users/anshulk/Desktop/FMS./fms_team-10/fms_frontend/FMS Frontend/FMS Frontend"

structure = {
    "FleetManager": [
        "SuperAdminAndRoleManagement",
        "VehicleManagement",
        "DriverVehicleAssignment",
        "TripCreationAndAssignment",
        "NotificationsAndAlerts",
        "Reporting",
        "Dashboard",
        "UserAuthentication"
    ],
    "Driver": [
        "UserAuthentication",
        "BasicTracking",
        "Geofencing",
        "TripLifecycleManagement",
        "IssueReporting",
        "Dashboard"
    ],
    "Maintenance": [
        "UserAuthentication",
        "PreTripInspection",
        "PostTripInspection",
        "MaintenanceScheduling",
        "WorkOrderManagement",
        "Dashboard"
    ]
}

def create_swift_file(path, class_name):
    content = f"""//
//  {class_name}.swift
//  FMS Frontend
//
"""
    with open(path, "w") as f:
        f.write(content)

for core, features in structure.items():
    for feature in features:
        # Create MVC/MVVM folders here? The prompt says "with each sub-folder being a feature. Follow MVVM structure."
        # Usually inside the feature folder we have the files for MVVM, or subfolders.
        # Let's create subfolders for MVVM.
        
        feature_dir = os.path.join(base_dir, core, feature)
        os.makedirs(feature_dir, exist_ok=True)
        
        # MVVM
        for layer in ["Models", "Views", "ViewModels"]:
            layer_dir = os.path.join(feature_dir, layer)
            os.makedirs(layer_dir, exist_ok=True)
            
            # Create the files inside
            suffix = layer[:-1] if layer != "Views" else "View" # Model, View, ViewModel
            file_name = f"{feature}{suffix}"
            file_path = os.path.join(layer_dir, f"{file_name}.swift")
            create_swift_file(file_path, file_name)

print("Project structure created successfully!")
