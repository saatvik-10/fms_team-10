import Foundation
import CoreLocation
import GoogleMaps
import Combine

class NavigationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published UI State
    @Published var currentInstruction: String = "Calculating route..."
    @Published var nextInstruction: String = ""
    @Published var etaText: String = "--"
    @Published var distanceRemaining: String = "--"
    @Published var polylineString: String = ""
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0

    // MARK: - Internal State
    private let locationManager = CLLocationManager()
    let trip: Trip

    // Uses clean NavigationInstruction — no HTML, no formatting in ViewModel
    var rawSteps: [NavigationInstruction] = []
    var currentStepIndex = 0
    private var currentGMSPath: GMSPath?
    private var lastLocation: CLLocation?
    private var isFetching = false
    private var hasStartedInitialFetch = false
    // MARK: - Init

    init(trip: Trip) {
        self.trip = trip
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.headingFilter = 5
        locationManager.requestWhenInUseAuthorization()
        // startUpdatingLocation/Heading called in locationManagerDidChangeAuthorization
    }

    // MARK: - Public Entry Point

    func startNavigation() {
        hasStartedInitialFetch = false

        if let existing = locationManager.location {
            currentLocation = existing.coordinate
            fetchSegmentRoute(from: existing.coordinate)
        }
        // Otherwise first didUpdateLocations triggers fetch
    }

    // MARK: - Route Fetch (user location → next stop only)

    private func fetchSegmentRoute(from origin: CLLocationCoordinate2D? = nil) {
        guard !isFetching else { return }

        let resolvedOrigin: CLLocationCoordinate2D
        if let o = origin {
            resolvedOrigin = o
        } else if let c = currentLocation {
            resolvedOrigin = c
        } else if let l = locationManager.location?.coordinate {
            resolvedOrigin = l
        } else {
            print("[Nav] No location yet — waiting for GPS fix")
            return
        }

        guard let destination = CLLocationCoordinate2D?(trip.destination.coordinate) else {
            print("[Nav] No destination available")
            return
        }

        print("[Nav] Fetching segment: \(resolvedOrigin) → \(destination)")
        isFetching = true

        Task {
            do {
                let result = try await GoogleDirectionsService.shared.fetchSegmentDirections(
                    origin: resolvedOrigin,
                    destination: destination
                )
                await MainActor.run {
                    self.etaText            = result.eta
                    self.distanceRemaining  = result.distance
                    self.polylineString     = result.polyline
                    self.rawSteps           = result.steps      // [NavigationInstruction] — already clean
                    self.currentStepIndex   = 0
                    self.currentGMSPath     = GMSPath(fromEncodedPath: result.polyline)
                    self.updateInstructions()
                    self.isFetching         = false
                    print("[Nav] Route loaded: eta=\(result.eta) dist=\(result.distance)")
                }
            } catch {
                await MainActor.run {
                    self.currentInstruction = "Route unavailable. Retrying..."
                    self.isFetching = false
                    print("[Nav] Fetch error: \(error.localizedDescription)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.fetchSegmentRoute()
                    }
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("[Nav] Auth status: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        case .denied, .restricted:
            print("[Nav] Location denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
        }

        // First location fix → trigger initial route fetch
        if !hasStartedInitialFetch {
            hasStartedInitialFetch = true
            DispatchQueue.main.async {
                self.fetchSegmentRoute(from: location.coordinate)
            }
            lastLocation = location
            return
        }

        // Off-route detection
        if let path = currentGMSPath,
           !GMSGeometryIsLocationOnPathTolerance(location.coordinate, path, true, 50.0) {
            let dist = lastLocation?.distance(from: location) ?? 100
            if dist >= 100 {
                lastLocation = location
                DispatchQueue.main.async {
                    self.currentInstruction = "Rerouting..."
                    self.fetchSegmentRoute(from: location.coordinate)
                }
                return
            }
        }

        // Periodic reroute — keeps polyline origin close to user
        let distSinceLast = lastLocation?.distance(from: location) ?? 0
        if distSinceLast >= 80 {
            lastLocation = location
            fetchSegmentRoute(from: location.coordinate)
            return
        }

        let timeSinceLast = lastLocation.map { location.timestamp.timeIntervalSince($0.timestamp) } ?? 30
        if timeSinceLast > 10 { lastLocation = location }

        // Step-level progression — uses endLocation from NavigationInstruction
        guard currentStepIndex < rawSteps.count else { return }
        let step    = rawSteps[currentStepIndex]
        let stepEnd = CLLocation(latitude: step.endLocation.latitude,
                                 longitude: step.endLocation.longitude)
        if location.distance(from: stepEnd) < 25.0 {
            DispatchQueue.main.async {
                self.currentStepIndex += 1
                self.updateInstructions()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async { self.userHeading = h }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Nav] Location error: \(error.localizedDescription)")
    }

    // MARK: - Instruction Updates (no HTML or string formatting here)

    private func updateInstructions() {
        guard currentStepIndex < rawSteps.count else {
            currentInstruction = "Arrived at destination"
            nextInstruction = ""
            return
        }
        // fullText is already formatted by the service: "Turn right onto X in 300 m"
        currentInstruction = rawSteps[currentStepIndex].fullText
        nextInstruction    = currentStepIndex + 1 < rawSteps.count
            ? rawSteps[currentStepIndex + 1].fullText
            : ""
    }
}
