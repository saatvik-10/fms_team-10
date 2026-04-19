import Foundation

struct MockDataProvider {
    // ... previous dashboard stats ...
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
    
    static let shipments: [ShipmentActivity] = [
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Electronic", company: "Tata Logistics", arrivalTime: "24 Dec 2023", route: "BOM - PNQ", price: "₹5,872.90", status: .delivered),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Industrial", company: "Mahindra Logistics", arrivalTime: "24 Dec 2023", route: "BOM - PNQ", price: "₹5,872.90", status: .inTransit),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "FMCG", company: "Delhivery", arrivalTime: "24 Dec 2023", route: "BOM - PNQ", price: "₹5,872.90", status: .pending),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Auto Parts", company: "Eicher Motors", arrivalTime: "24 Dec 2023", route: "BOM - PNQ", price: "₹5,872.90", status: .processing)
    ]
    
    static let fleetStatus = FleetVehicleStatus(
        active: 12,
        activeTrend: "+2%",
        maintenance: 04,
        idle: 03,
        critical: 01
    )
    
    static let assessments: [SmartFleetAssessment] = [
        SmartFleetAssessment(truckName: "Tata Prima 4028.S", truckID: "TRK-9042", routeFrom: "DEL", routeTo: "JAI", etaTime: "16:15", etaDay: "Today", status: .inTransit, imageName: "truck_freightliner_m2"),
        SmartFleetAssessment(truckName: "Tata Ace EV", truckID: "EV-9910", routeFrom: "BLR Hub", routeTo: "HSR Lyt", etaTime: "Critical", etaDay: "", status: .alertReceived, imageName: "van_rivian"),
        SmartFleetAssessment(truckName: "Eicher Pro 6028", truckID: "TRK-5502", routeFrom: "MAA", routeTo: "COK", etaTime: "11:00", etaDay: "Today", status: .inTransit, imageName: "truck_kenworth_t680"),
        SmartFleetAssessment(truckName: "BharatBenz 3523R", truckID: "TRK-2101", routeFrom: "HYD", routeTo: "PNQ", etaTime: "21:30", etaDay: "Today", status: .inTransit, imageName: "truck_volvo_fh")
    ]
    
    static let maintenanceAlerts: [MaintenanceAlert] = [
        MaintenanceAlert(title: "Insurance Renewal", detail: "Overdue • Policy #XX-990 • Action Required", iconName: "exclamationmark.triangle.fill", status: "Urgent"),
        MaintenanceAlert(title: "Compliance Audit", detail: "Due in 4 days • Regional Hub Compliance Unit", iconName: "doc.text.fill", status: "Scheduled")
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

    // MARK: - Drivers Dataset (from Image 1 & 3)
    static let drivers: [Driver] = [
        Driver(id: "KM-1029", name: "Rahul Sharma", title: "Class A CDL Expert", licenseNum: "DL-99203381", licenseExp: "Oct 2026", status: .active, rating: 4.92, efficiency: "98.4%", totalTrips: 124, totalHours: 8420, activityLog: mockActivityLog, currentVehicleID: "VX-7702", activeRoute: "IH-35 North bound", eta: "14:20 (22 mins)"),
        Driver(id: "KM-1044", name: "Priya Patel", title: "Heavy Haul Specialist", licenseNum: "DL-44810293", licenseExp: "Mar 2025", status: .onTrip, rating: 4.88, efficiency: "95.2%", totalTrips: 89, totalHours: 6200, activityLog: [], currentVehicleID: "VN-4209", activeRoute: "Route B-12", eta: "1h 12m"),
        Driver(id: "KM-1011", name: "Amit Kumar", title: "Regional Dispatcher", licenseNum: "DL-88293310", licenseExp: "Jan 2027", status: .offDuty, rating: 4.95, efficiency: "99.1%", totalTrips: 156, totalHours: 9800, activityLog: [], currentVehicleID: nil, activeRoute: nil, eta: nil),
        Driver(id: "KM-1052", name: "Sneha Rao", title: "Long Haul Driver", licenseNum: "DL-11029384", licenseExp: "Aug 2025", status: .active, rating: 4.76, efficiency: "94.8%", totalTrips: 72, totalHours: 5100, activityLog: [], currentVehicleID: "EV-9910", activeRoute: "Sector 4", eta: "45m"),
        Driver(id: "KM-1008", name: "Vikram Singh", title: "Safety Protocol Lead", licenseNum: "DL-77382291", licenseExp: "Dec 2024", status: .onTrip, rating: 4.99, efficiency: "99.9%", totalTrips: 210, totalHours: 12400, activityLog: [], currentVehicleID: "VX-8812", activeRoute: "North Route", eta: "10m")
    ]
    
    static let mockActivityLog: [ActivityEvent] = [
        ActivityEvent(title: "Cargo Delivery Completed", detail: "Drop-off: WH-B12", time: "2h ago", type: "completed", value: "+₹2400.00"),
        ActivityEvent(title: "Refueling Stopped", detail: "IOCL #429", time: "5h ago", type: "refueling", value: "14.2 L"),
        ActivityEvent(title: "Shift Started", detail: "Main Dpt", time: "8h ago", type: "started", value: "SYSTEM"),
        ActivityEvent(title: "Hard Braking Incident", detail: "Rt A-1", time: "Yesterday", type: "incident", value: "FLAGGED")
    ]

    // MARK: - Vehicles Dataset (Expanded)
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
            currentTrip: VehicleTrip(origin: "DEL", destination: "JAI", progress: 0.72, eta: "4:15 PM", date: nil, distance: nil, duration: nil),
            assignedDriver: drivers.first,
            maintenance: VehicleMaintenance(
                nextService: "Oct 24, 2023",
                inspectionStatus: "Completed",
                alerts: [MaintenanceAlert(title: "Minor: Left Tail Lamp", detail: "LOGGED 2D AGO", iconName: "exclamationmark.triangle.fill", status: "Minor")]
            ),
            history: [
                VehicleTrip(origin: "DEL", destination: "AGR", progress: 1.0, eta: "", date: "OCT 12", distance: "297 KM", duration: "4.5 HRS"),
                VehicleTrip(origin: "AGR", destination: "NDA", progress: 1.0, eta: "", date: "OCT 09", distance: "284 KM", duration: "4.2 HRS")
            ],
            reports: [
                VehicleReport(title: "Monthly Maintenance Report - Sept", subtitle: "PDF • 1.2 MB • SEP 30, 2023", fileType: "pdf", date: "SEP 30, 2023", serviceProvider: "Fleet Care Solutions", tasks: [
                    ReportTask(description: "Oil and Filter Change", cost: "₹1200.00"),
                    ReportTask(description: "Brake Pad Replacement", cost: "₹4500.00")
                ], totalCost: "₹5700.00"),
                VehicleReport(title: "Trip Efficiency Analysis - Oct", subtitle: "PDF • 840 KB • OCT 15, 2023", fileType: "pdf", date: "OCT 15, 2023", serviceProvider: "Logistics Insights AI", tasks: [
                    ReportTask(description: "Fuel Efficiency Audit", cost: "₹0.00"),
                    ReportTask(description: "Route Optimization Report", cost: "₹0.00")
                ], totalCost: "₹0.00")
            ],
            assessmentReason: "Route Optimized: Fuel Savings +12%"
        ),
        Vehicle(
            id: "VN-4209",
            make: "Mahindra",
            model: "Bolero Pik-Up",
            type: "Van",
            status: .idle,
            imageName: "van_ford",
            year: "2022",
            color: "White",
            odometer: "12,140",
            operationalStatus: "OPERATIONAL",
            currentTrip: nil,
            assignedDriver: drivers[1],
            maintenance: VehicleMaintenance(nextService: "Nov 12, 2023", inspectionStatus: "Pending", alerts: []),
            history: [],
            reports: [],
            assessmentReason: nil
        ),
        Vehicle(
            id: "EV-9910",
            make: "Tata",
            model: "Ace EV",
            type: "EV",
            status: .maintenance,
            imageName: "van_rivian",
            year: "2024",
            color: "Deep Blue",
            odometer: "3,420",
            operationalStatus: "UNDER SERVICE",
            currentTrip: nil,
            assignedDriver: drivers[2],
            maintenance: VehicleMaintenance(nextService: "Oct 18, 2023", inspectionStatus: "In Progress", alerts: [MaintenanceAlert(title: "Battery Optimization", detail: "FIRMWARE UPGRADE", iconName: "bolt.fill", status: "Critical")]),
            history: [],
            reports: [
                VehicleReport(title: "Initial Compliance Report", subtitle: "PDF • 500 KB • AUG 12, 2023", fileType: "pdf", date: "AUG 12, 2023", serviceProvider: "Tata Motors Service", tasks: [
                    ReportTask(description: "Standard Inspection", cost: "₹1,500.00")
                ], totalCost: "₹1,500.00")
            ],
            assessmentReason: "Predictive: Battery Thermal Variance"
        ),
        Vehicle(
            id: "TRK-2101",
            make: "Ashok Leyland",
            model: "Captain",
            type: "Truck",
            status: .inTransit,
            imageName: "truck_volvo_fh",
            year: "2023",
            color: "Titanium Grey",
            odometer: "68,200",
            operationalStatus: "OPERATIONAL",
            currentTrip: VehicleTrip(origin: "HYD", destination: "PNQ", progress: 0.45, eta: "9:30 PM", date: nil, distance: nil, duration: nil),
            assignedDriver: drivers[3],
            maintenance: VehicleMaintenance(nextService: "Nov 01, 2023", inspectionStatus: "Completed", alerts: []),
            history: [],
            reports: [],
            assessmentReason: "On Schedule: High Efficiency"
        ),
        Vehicle(
            id: "VN-1100",
            make: "Mahindra",
            model: "Supro",
            type: "Van",
            status: .idle,
            imageName: "van_sprinter",
            year: "2023",
            color: "Iridium Silver",
            odometer: "8,900",
            operationalStatus: "OPERATIONAL",
            currentTrip: nil,
            assignedDriver: drivers[4],
            maintenance: VehicleMaintenance(nextService: "Dec 10, 2023", inspectionStatus: "Completed", alerts: []),
            history: [],
            reports: [],
            assessmentReason: nil
        ),
        Vehicle(
            id: "TRK-5502",
            make: "Eicher",
            model: "Pro 6000",
            type: "Truck",
            status: .inTransit,
            imageName: "truck_kenworth_t680",
            year: "2024",
            color: "Radiant Red",
            odometer: "15,200",
            operationalStatus: "OPERATIONAL",
            currentTrip: VehicleTrip(origin: "MAA", destination: "COK", progress: 0.88, eta: "11:00 AM", date: nil, distance: nil, duration: nil),
            assignedDriver: drivers.first,
            maintenance: VehicleMaintenance(nextService: "Jan 15, 2024", inspectionStatus: "Completed", alerts: []),
            history: [],
            reports: [],
            assessmentReason: "Route Optimized: Avoided Congestion"
        )
    ]
}
