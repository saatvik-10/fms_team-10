import Foundation

struct MockDataProvider {
    static let dashboardStats = FleetManagerDashboardStats(
        totalShipments: 172,
        totalShipmentsTrend: "+1,92%",
        pendingPackages: 42,
        pendingPackagesTrend: "+1,89%",
        deliveryShipments: 16,
        deliveryShipmentsTrend: "-0,98%",
        maintenanceSummary: "Real-time status of 18 pending service requirements across the fleet.",
        criticalMass: 0.22
    )
    
    static let shipments: [ShipmentActivity] = []
    
    static let fleetStatus = FleetVehicleStatus(
        active: 12,
        activeTrend: "+2%",
        maintenance: 04,
        idle: 03,
        critical: 01
    )
    
    static let assessments: [SmartFleetAssessment] = [
        SmartFleetAssessment(truckName: "Tata Prima 4028.S", truckID: "TRK-9042", routeFrom: "DEL", routeTo: "JAI", etaTime: "16:15", etaDay: "Today", status: .inTransit, imageName: "truck_freightliner_m2"),
        SmartFleetAssessment(truckName: "Tata Ace EV", truckID: "EV-9910", routeFrom: "BLR Hub", routeTo: "HSR Lyt", etaTime: "Critical", etaDay: "", status: .alertReceived, imageName: "van_rivian")
    ]
    
    static let maintenanceAlerts: [FleetMaintenanceAlert] = [
        FleetMaintenanceAlert(
            title: "Brake Pad Wear",
            detail: "TRK-9042 • Wear Level: 85% • Priority: Urgent",
            iconName: "exclamationmark.triangle.fill",
            status: "Urgent",
            vehicleID: "TRK-9042",
            taskDetails: "Replace front brake pads and inspect rotors. Brake performance has degraded by 15%.",
            notes: "Driver reported squealing noise when braking on downhills.",
            media: ["brake_part", "tire_part"],
            isAccepted: false
        ),
        FleetMaintenanceAlert(
            title: "Engine Oil Life",
            detail: "EV-9910 • Life: 10% • Priority: Scheduled",
            iconName: "drop.fill",
            status: "Scheduled",
            vehicleID: "EV-9910",
            taskDetails: "Standard oil and filter change. Inspect for any potential leaks.",
            notes: "Last service was 12,000 km ago.",
            media: ["engine_part"],
            isAccepted: false
        )
    ]
    
    static let emissionData: [EmissionData] = [
        EmissionData(day: "MON", value: 10.5, isCurrent: false),
        EmissionData(day: "TUE", value: 12.0, isCurrent: false),
        EmissionData(day: "WED", value: 15.0, isCurrent: false),
        EmissionData(day: "THU", value: 18.2, isCurrent: true),
        EmissionData(day: "FRI", value: 14.5, isCurrent: false),
        EmissionData(day: "SAT", value: 8.0, isCurrent: false),
        EmissionData(day: "SUN", value: 9.5, isCurrent: false)
    ]

    static let drivers: [Driver] = [
        Driver(id: "KM-1029", name: "Rahul Sharma", title: "LMV-NT Certified Driver", licenseNum: "DL-99203381", licenseExp: "Oct 2026", status: .active, rating: 4.92, efficiency: "98.4%", totalTrips: 124, totalHours: 8420, activityLog: [], currentVehicleID: "TRK-9042", vehicleClasses: ["LMV-NT"], activeRoute: "IH-35 North bound", eta: "14:20"),
        Driver(id: "KM-1044", name: "Priya Patel", title: "HGV Specialist", licenseNum: "DL-44810293", licenseExp: "Mar 2025", status: .onTrip, rating: 4.88, efficiency: "95.2%", totalTrips: 89, totalHours: 6200, activityLog: [], currentVehicleID: "EV-9910", vehicleClasses: ["LMV-GV", "HGV"], activeRoute: "Route B-12", eta: "1h 12m")
    ]
    
    static let vehicles: [Vehicle] = [
        Vehicle(
            id: "TRK-9042",
            make: "Tata",
            model: "Prima",
            type: "Truck",
            status: .inTransit,
            imageName: "truck_freightliner_m2",
            year: "2023",
            color: "Silver Birch Metallic",
            odometer: "42,892",
            operationalStatus: "OPERATIONAL",
            currentTrip: VehicleTrip(origin: "DEL", destination: "JAI", progress: 0.72, eta: "4:15 PM", date: "Today", distance: "250 KM", duration: "4 HRS", costEstimate: "₹8500.00", startTime: Date(), status: .inTransit),
            assignedDriver: drivers[0],
            maintenance: VehicleMaintenance(nextService: "Oct 24, 2023", inspectionStatus: "Completed", alerts: []),
            history: [
                VehicleTrip(origin: "MUM", destination: "PUN", progress: 1.0, eta: "Completed", date: "Apr 18, 2026", distance: "150 KM", duration: "3h", costEstimate: "₹4,200", startTime: nil, status: .completed),
                VehicleTrip(origin: "AMD", destination: "SUR", progress: 1.0, eta: "Completed", date: "Apr 16, 2026", distance: "280 KM", duration: "5h", costEstimate: "₹7,800", startTime: nil, status: .completed)
            ],
            reports: [],
            assessmentReason: "Route Optimized: Fuel Savings +12%"
        ),
        Vehicle(
            id: "EV-9910",
            make: "Tata",
            model: "Ace EV",
            type: "EV",
            status: .idle,
            imageName: "van_rivian",
            year: "2024",
            color: "Deep Blue",
            odometer: "3,420",
            operationalStatus: "OPERATIONAL",
            currentTrip: nil,
            assignedDriver: drivers[1],
            maintenance: VehicleMaintenance(nextService: "Oct 18, 2023", inspectionStatus: "Completed", alerts: []),
            history: [
                VehicleTrip(origin: "BLR Hub", destination: "HSR", progress: 1.0, eta: "Completed", date: "Apr 19, 2026", distance: "12 KM", duration: "45m", costEstimate: "₹250", startTime: nil, status: .completed)
            ],
            reports: [],
            assessmentReason: nil
        ),
        Vehicle(
            id: "TRK-1088",
            make: "Mahindra",
            model: "Blazo X",
            type: "Truck",
            status: .maintenance,
            imageName: "truck_freightliner_m2",
            year: "2022",
            color: "White",
            odometer: "89,120",
            operationalStatus: "MAINTENANCE",
            currentTrip: nil,
            assignedDriver: nil,
            maintenance: VehicleMaintenance(nextService: "Overdue", inspectionStatus: "Pending", alerts: []),
            history: [],
            reports: [],
            assessmentReason: nil
        )
    ]
}
