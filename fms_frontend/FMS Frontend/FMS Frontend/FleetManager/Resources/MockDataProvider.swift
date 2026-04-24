import Foundation
import SwiftUI

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

    static let mockActivityLog: [ActivityEvent] = [
        ActivityEvent(title: "Cargo Delivery Completed", detail: "Drop-off: WH-B12", time: "2h ago", type: "completed", value: "+₹2400.00"),
        ActivityEvent(title: "Refueling Stopped", detail: "IOCL #429", time: "5h ago", type: "refueling", value: "14.2 L"),
        ActivityEvent(title: "Shift Started", detail: "Main Dpt", time: "8h ago", type: "started", value: "SYSTEM"),
    ]
    
    static let mileageData: [MileageData] = [
        MileageData(day: "Sun", value: 881),
        MileageData(day: "Mon", value: 786),
        MileageData(day: "Tue", value: 824),
        MileageData(day: "Wed", value: 1031),
        MileageData(day: "Thu", value: 549),
        MileageData(day: "Fri", value: 629),
        MileageData(day: "Sat", value: 1145)
    ]
    
    static let fuelTrendData: [FuelTrendData] = [
        FuelTrendData(month: "March 2021", value: 1540),
        FuelTrendData(month: "April 2021", value: 1100),
        FuelTrendData(month: "May 2021", value: 870)
    ]
    
    // Performance Trends (7-Day Sparklines)
    static let utilizationTrend: [HistoricalPoint] = [
        HistoricalPoint(label: "Mon", value: 65),
        HistoricalPoint(label: "Tue", value: 72),
        HistoricalPoint(label: "Wed", value: 68),
        HistoricalPoint(label: "Thu", value: 85),
        HistoricalPoint(label: "Fri", value: 78),
        HistoricalPoint(label: "Sat", value: 45),
        HistoricalPoint(label: "Sun", value: 40)
    ]
    
    static let efficiencyTrend: [HistoricalPoint] = [
        HistoricalPoint(label: "Mon", value: 42.5),
        HistoricalPoint(label: "Tue", value: 44.0),
        HistoricalPoint(label: "Wed", value: 41.2),
        HistoricalPoint(label: "Thu", value: 46.8),
        HistoricalPoint(label: "Fri", value: 45.1),
        HistoricalPoint(label: "Sat", value: 48.2),
        HistoricalPoint(label: "Sun", value: 47.5)
    ]
    
    static let costTrend: [HistoricalPoint] = [
        HistoricalPoint(label: "Mon", value: 34.2),
        HistoricalPoint(label: "Tue", value: 33.5),
        HistoricalPoint(label: "Wed", value: 35.8),
        HistoricalPoint(label: "Thu", value: 32.1),
        HistoricalPoint(label: "Fri", value: 31.5),
        HistoricalPoint(label: "Sat", value: 30.2),
        HistoricalPoint(label: "Sun", value: 29.8)
    ]
    
    static let idleTrend: [HistoricalPoint] = [
        HistoricalPoint(label: "Mon", value: 12),
        HistoricalPoint(label: "Tue", value: 15),
        HistoricalPoint(label: "Wed", value: 10),
        HistoricalPoint(label: "Thu", value: 18),
        HistoricalPoint(label: "Fri", value: 14),
        HistoricalPoint(label: "Sat", value: 25),
        HistoricalPoint(label: "Sun", value: 22)
    ]

    static let maintenanceCostPerVehicle: [HistoricalPoint] = [
        HistoricalPoint(label: "TRK-9042", value: 12400),
        HistoricalPoint(label: "EV-9910", value: 3200),
        HistoricalPoint(label: "TRK-1088", value: 18500),
        HistoricalPoint(label: "VN-4209", value: 5600),
        HistoricalPoint(label: "VX-7702", value: 9800)
    ]

    static let totalKmsTravelled: Double = 725428

    static let driverDistanceData: [HistoricalPoint] = [
        HistoricalPoint(label: "Rahul", value: 12400),
        HistoricalPoint(label: "Priya", value: 15600),
        HistoricalPoint(label: "Amit", value: 8900),
        HistoricalPoint(label: "Sneha", value: 11200),
        HistoricalPoint(label: "Vikram", value: 14500)
    ]

    static let travelsHistory: [HistoricalPoint] = [
        HistoricalPoint(label: "Jan", value: 45000),
        HistoricalPoint(label: "Feb", value: 52000),
        HistoricalPoint(label: "Mar", value: 48000),
        HistoricalPoint(label: "Apr", value: 61000),
        HistoricalPoint(label: "May", value: 55000)
    ]
    // MARK: - Drivers Dataset
    static let drivers: [Driver] = [
        Driver(id: "KM-1029", name: "Rahul Sharma", email: "rahul.s@fms.com", title: "Class A CDL Expert", licenseNum: "DL-99203381", licenseExp: "Oct 2026", status: .active, rating: 4.92, efficiency: "98.4%", totalTrips: 124, totalHours: 8420, activityLog: mockActivityLog, currentVehicleID: "VX-7702", vehicleClasses: ["Class A"], activeRoute: "IH-35 North bound", eta: "14:20 (22 mins)", phone: "+91 98765 43210"),
        Driver(id: "KM-1044", name: "Priya Patel", email: "priya.p@fms.com", title: "Heavy Haul Specialist", licenseNum: "DL-44810293", licenseExp: "Mar 2025", status: .onTrip, rating: 4.88, efficiency: "95.2%", totalTrips: 89, totalHours: 6200, activityLog: [], currentVehicleID: "VN-4209", vehicleClasses: ["Class A", "Class B"], activeRoute: "Route B-12", eta: "1h 12m", phone: "+91 91234 56789"),
        Driver(id: "KM-1011", name: "Amit Kumar", email: "amit.k@fms.com", title: "Regional Dispatcher", licenseNum: "DL-88293310", licenseExp: "Jan 2027", status: .offDuty, rating: 4.95, efficiency: "99.1%", totalTrips: 156, totalHours: 9800, activityLog: [], currentVehicleID: nil, vehicleClasses: ["Class B"], activeRoute: nil, eta: nil, phone: "+91 99887 76655"),
        Driver(id: "KM-1052", name: "Sneha Rao", email: "sneha.r@fms.com", title: "Long Haul Driver", licenseNum: "DL-11029384", licenseExp: "Aug 2025", status: .active, rating: 4.76, efficiency: "94.8%", totalTrips: 72, totalHours: 5100, activityLog: [], currentVehicleID: "EV-9910", vehicleClasses: ["Class A"], activeRoute: "Sector 4", eta: "45m", phone: "+91 90000 11111"),
        Driver(id: "KM-1008", name: "Vikram Singh", email: "vikram.s@fms.com", title: "Safety Protocol Lead", licenseNum: "DL-77382291", licenseExp: "Dec 2024", status: .onTrip, rating: 4.99, efficiency: "99.9%", totalTrips: 210, totalHours: 12400, activityLog: [], currentVehicleID: "VX-8812", vehicleClasses: ["Class A", "Class D"], activeRoute: "North Route", eta: "10m", phone: "+91 91111 22222")
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
            currentTrip: VehicleTrip(vehicleID: "TRK-9042", origin: "DEL", destination: "JAI", progress: 0.72, eta: "4:15 PM", date: "Today", distance: "250 KM", duration: "4 HRS", costEstimate: "₹8500.00", startTime: Date(), status: .inTransit, productType: "Steel Coils", loadAmount: "25 Tons"),
            assignedDriver: drivers[0],
            maintenance: VehicleMaintenance(nextService: "Oct 24, 2023", inspectionStatus: "Completed", alerts: []),
            history: [
                VehicleTrip(vehicleID: "TRK-9042", origin: "MUM", destination: "PUN", progress: 1.0, eta: "Completed", date: "Apr 18, 2026", distance: "150 KM", duration: "3h", costEstimate: "₹4,200", startTime: nil, status: .completed, productType: "Pharma Supplies", loadAmount: "8 Tons"),
                VehicleTrip(vehicleID: "TRK-9042", origin: "AMD", destination: "SUR", progress: 1.0, eta: "Completed", date: "Apr 16, 2026", distance: "280 KM", duration: "5h", costEstimate: "₹7,800", startTime: nil, status: .completed, productType: "Industrial Valves", loadAmount: "12 Tons"),
                VehicleTrip(vehicleID: "TRK-9042", origin: "DEL", destination: "AGR", progress: 1.0, eta: "Completed", date: "Apr 14, 2026", distance: "210 KM", duration: "4h", costEstimate: "₹6,100", startTime: nil, status: .completed, productType: "Textiles", loadAmount: "10 Tons")
            ],
            reports: [],
            assessmentReason: "Route Optimized: Fuel Savings +12%",
            plateNumber: "DL 1C AB 9042",
            registrationNumber: "REG-IND-442033"
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
                VehicleTrip(vehicleID: "EV-9910", origin: "BLR Hub", destination: "HSR", progress: 1.0, eta: "Completed", date: "Apr 19, 2026", distance: "12 KM", duration: "45m", costEstimate: "₹250", startTime: nil, status: .completed, productType: "E-commerce Parcels", loadAmount: "1.2 Tons"),
                VehicleTrip(vehicleID: "EV-9910", origin: "KOR", destination: "IND", progress: 1.0, eta: "Completed", date: "Apr 17, 2026", distance: "15 KM", duration: "1h", costEstimate: "₹300", startTime: nil, status: .completed, productType: "Fresh Produce", loadAmount: "0.8 Tons")
            ],
            reports: [],
            assessmentReason: nil,
            plateNumber: "KA 01 EV 9910",
            registrationNumber: "REG-IND-112099"
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
            assignedDriver: drivers[2],
            maintenance: VehicleMaintenance(nextService: "Overdue", inspectionStatus: "Pending", alerts: []),
            history: [
                VehicleTrip(vehicleID: "TRK-1088", origin: "HYD", destination: "BLR", progress: 1.0, eta: "Completed", date: "Apr 15, 2026", distance: "570 KM", duration: "12h", costEstimate: "₹18,500", startTime: nil, status: .completed, productType: "General Freight", loadAmount: "18 Tons"),
                VehicleTrip(vehicleID: "TRK-1088", origin: "MAA", destination: "BLR", progress: 1.0, eta: "Completed", date: "Apr 12, 2026", distance: "340 KM", duration: "7h", costEstimate: "₹12,400", startTime: nil, status: .completed, productType: "Auto Parts", loadAmount: "15 Tons")
            ],
            reports: [],
            assessmentReason: nil,
            plateNumber: "MH 12 XB 1088",
            registrationNumber: "REG-IND-882012"
        )
    ]
    
    // MARK: - Maintenance Personnel Dataset
    static let maintenancePersonnel: [MaintenancePersonnel] = [
        MaintenancePersonnel(name: "Arjun Mehta", phone: "+91 98765 43210", email: "arjun.m@fms.com", dob: Calendar.current.date(from: DateComponents(year: 1989, month: 5, day: 15)) ?? Date(), currentAssignment: "TRK-9042"),
        MaintenancePersonnel(name: "Sunita Deshmukh", phone: "+91 87654 32109", email: "sunita.d@fms.com", dob: Calendar.current.date(from: DateComponents(year: 1994, month: 8, day: 22)) ?? Date(), currentAssignment: "EV-9910"),
        MaintenancePersonnel(name: "Rajesh Khanna", phone: "+91 76543 21098", email: "rajesh.k@fms.com", dob: Calendar.current.date(from: DateComponents(year: 1981, month: 12, day: 10)) ?? Date(), currentAssignment: nil),
        MaintenancePersonnel(name: "Kavita Singh", phone: "+91 65432 10987", email: "kavita.s@fms.com", dob: Calendar.current.date(from: DateComponents(year: 1992, month: 3, day: 30)) ?? Date(), currentAssignment: "VN-4209")
    ]
}
