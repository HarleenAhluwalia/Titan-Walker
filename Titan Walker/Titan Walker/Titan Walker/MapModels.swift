//
//  MapModels.swift
//  Titan Walker
//
//  Created by Ling on 9/6/25.
//
import SwiftUI
import MapKit
import CoreLocation
import Foundation
/****************************/
/**    Data Models & Extensions    */
/****************************/
// Coordinate location of CSUF buildings
extension CLLocationCoordinate2D {
    static let HUM: CLLocationCoordinate2D  = .init(latitude: 33.880421, longitude: -117.884185)
    static let MH: CLLocationCoordinate2D   = .init(latitude: 33.879662, longitude: -117.885496)
    static let CS: CLLocationCoordinate2D   = .init(latitude: 33.882372, longitude: -117.882634)
    static let E: CLLocationCoordinate2D    = .init(latitude: 33.882263, longitude: -117.883194)
    static let EC: CLLocationCoordinate2D   = .init(latitude: 33.881243, longitude: -117.884358)
    static let KHS: CLLocationCoordinate2D  = .init(latitude: 33.882819, longitude: -117.8855430)
    static let PL: CLLocationCoordinate2D   = .init(latitude: 33.881555, longitude: -117.885201)
    static let GH: CLLocationCoordinate2D   = .init(latitude: 33.879757, longitude: -117.884189)
    static let VA: CLLocationCoordinate2D   = .init(latitude: 33.880692, longitude: -117.889134)
    static let LH: CLLocationCoordinate2D   = .init(latitude: 33.878932, longitude: -117.884650)
    static let DBH: CLLocationCoordinate2D  = .init(latitude: 33.879245, longitude: -117.885131)
    static let SGMH: CLLocationCoordinate2D = .init(latitude: 33.878732, longitude: -117.883978)
    static let CP: CLLocationCoordinate2D   = .init(latitude: 33.877551, longitude: -117.883413)
    static let CPAC: CLLocationCoordinate2D = .init(latitude: 33.880112, longitude: -117.886937)
}
// Building info structure - REFERENCE TYPE
class BuildingReference: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    @Published var isAccessible: Bool = true
    var nodeType: String
    
    init(name: String, coordinate: CLLocationCoordinate2D, nodeType: String, isAccessible: Bool = true) {
        self.name = name
        self.coordinate = coordinate
        self.nodeType = nodeType
        self.isAccessible = isAccessible
    }
}
// Keep the original Building struct  just in case
struct Building: Identifiable {
    var id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var nodeType: String
    var isAccessible: Bool = true
    
    // Convenience initializer from BuildingReference
    init(from reference: BuildingReference) {
        self.id = reference.id
        self.name = reference.name
        self.coordinate = reference.coordinate
        self.nodeType = reference.nodeType
        self.isAccessible = reference.isAccessible
    }
}
struct Place: Identifiable {
    let name: String
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
}
/****************************/
/**   Building Manager    */
/****************************/
class BuildingManager: ObservableObject {
    @Published var buildings: [BuildingReference] = []
    
    // Single source of truth with computed properties
    var allBuildings: [BuildingReference] { buildings }
    
    var accessibleBuildings: [BuildingReference] {
        buildings.filter { $0.isAccessible }
    }
    
    // Initialize with default buildings
    func initializeDefaultBuildings() {
        buildings = [
            BuildingReference(name: "Humanities", coordinate: .HUM, nodeType: "none", isAccessible: true),
            BuildingReference(name: "McCarthy Hall", coordinate: .MH, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Computer Science", coordinate: .CS, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Engineering", coordinate: .E, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Education", coordinate: .EC, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Kinesiology", coordinate: .KHS, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Pollak Library", coordinate: .PL, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Gordon Hall", coordinate: .GH, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Visual Arts", coordinate: .VA, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Langsdorf Hall", coordinate: .LH, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Dan Black Hall", coordinate: .DBH, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Mihaylo Hall", coordinate: .SGMH, nodeType: "none", isAccessible: true),
            BuildingReference(name: "College Park", coordinate: .CP, nodeType: "none", isAccessible: true),
            BuildingReference(name: "Clayes Performing Arts Center", coordinate: .CPAC, nodeType: "none", isAccessible: true)
        ]
    }
    
    func toggleBuildingAccess(_ building: BuildingReference) {
        // Find and update the specific building
        if let index = buildings.firstIndex(where: { $0.id == building.id }) {
            buildings[index].isAccessible.toggle()
            // Force UI update by modifying the published property
            objectWillChange.send()
        }
    }
    
    func addBuilding(_ building: BuildingReference) {
        buildings.append(building)
        objectWillChange.send()
    }
    
    func removeBuilding(_ building: BuildingReference) {
        buildings.removeAll { $0.id == building.id }
        objectWillChange.send()
    }
    
    func getBuilding(by id: UUID) -> BuildingReference? {
        buildings.first { $0.id == id }
    }
    
    func getBuildingAccessStatus(_ building: BuildingReference) -> Bool {
        building.isAccessible
    }
}
/****************************/
/**   Map Data & State    */
/****************************/
class MapData: ObservableObject {
    // Camera position for map
    @Published var cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 33.883121, longitude: -117.886101), latitudinalMeters: 850, longitudinalMeters: 850))
    
    // Map interaction state
    @Published var selectedAnnotation: UUID? = nil
    @Published var selectedBuilding: BuildingReference? = nil
    @Published var showSheet = false
    @Published var route: MKRoute?
    
    // Building management
    @Published var buildingManager = BuildingManager()
    
    // Location tracking
    let locationManager = CLLocationManager()
    @Published var tappedCoordinate: CLLocationCoordinate2D?
    @Published var pressLocation: CGPoint = .zero
    
    // User location tracking
    @Published var userLocation: CLLocationCoordinate2D?
    private var locationTask: Task<Void, Never>?
    private var lastRouteCalculationLocation: CLLocationCoordinate2D?
    private let recalculationThreshold: CLLocationDistance = 10.0 // meters
    
    // ETA and Distance
    @Published var expectedTravelTime: TimeInterval = 0 // in minutes
    @Published var distance: CLLocationDistance = 0     // in meters
    
    @Published var routeSteps: [MKRoute.Step] = []
    
    init() {
        buildingManager.initializeDefaultBuildings()
    }
}
/****************************/
/**   Helper Functions    */
/****************************/
extension MapData {
    
    func colorFor(nodeType: String) -> Color {
        switch nodeType {
        case "outside":
            return Color.blue
        case "inside":
            return Color.green
        default:
            return Color.red
        }
    }
    
    // Start continuous location tracking
    func startLocationTracking() {
        locationTask?.cancel()
        
        locationTask = Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                
                for try await update in updates {
                    guard let location = update.location else { continue }
                    
                    let newCoordinate = location.coordinate
                    
                    await MainActor.run {
                        userLocation = newCoordinate
                        
                        // Auto-adjust route if we have an active destination
                        if let selectedBuilding = selectedBuilding, route != nil {
                            // Only recalculate if user moved significantly
                            if shouldRecalculateRoute(for: newCoordinate) {
                                recalculateRoute(to: selectedBuilding.coordinate)
                                lastRouteCalculationLocation = newCoordinate
                            }
                        }
                    }
                }
            } catch {
                print("Location tracking error: \(error)")
            }
        }
    }
    
    // Stop location tracking
    func stopLocationTracking() {
        locationTask?.cancel()
        locationTask = nil
    }
    
    // Check if route should be recalculated based on distance threshold
    private func shouldRecalculateRoute(for newLocation: CLLocationCoordinate2D) -> Bool {
        guard let lastLocation = lastRouteCalculationLocation else {
            return true // First calculation
        }
        
        let location1 = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
        let location2 = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
        
        return location1.distance(from: location2) > recalculationThreshold
    }
    
    // Get user location (one-time)
    func getUserLocation() async -> CLLocationCoordinate2D? {
        // Return the tracked location if available
        if let trackedLocation = userLocation {
            return trackedLocation
        }
        
        // Fallback to one-time location fetch
        do {
            let updates = CLLocationUpdate.liveUpdates()
            for try await update in updates {
                if let location = update.location?.coordinate {
                    await MainActor.run {
                        userLocation = location
                    }
                    return location
                }
                break // Just get one update
            }
        } catch {
            print("Cannot get user location: \(error)")
        }
        
        return nil
    }
    
    // Get directions (initial)
    func getDirection(to destination: CLLocationCoordinate2D, errorManager: ErrorManager, isAdmin: Bool = false) {
        // Check if destination building is accessible for regular users
        if !isAdmin {
            // Find the building at this coordinate
            let destinationBuilding = buildingManager.allBuildings.first { building in
                abs(building.coordinate.latitude - destination.latitude) < 0.0001 &&
                abs(building.coordinate.longitude - destination.longitude) < 0.0001
            }
            
            if let building = destinationBuilding, !building.isAccessible {
                Task { @MainActor in
                    errorManager.showError("\(building.name) is currently closed and inaccessible.")
                }
                return
            }
        }
        
        Task {
            if let currentLocation = await getUserLocation() {
                await MainActor.run {
                    userLocation = currentLocation
                    lastRouteCalculationLocation = currentLocation
                    calculateRoute(from: currentLocation, to: destination)
                    startLocationTracking() // Ensure tracking is active
                }
            } else {
                // Show error on main thread
                await MainActor.run {
                    errorManager.showError("Unable to get your current location. Please check your location permissions and try again.")
                }
            }
        }
    }
    
    // Recalculate route (for auto-updates)
    func recalculateRoute(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = userLocation else { return }
        calculateRoute(from: currentLocation, to: destination)
    }
    
    // Core route calculation
    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: source))
            request.destination = MKMapItem(placemark: .init(coordinate: destination))
            request.transportType = .walking
            
            do {
                let directions = try await MKDirections(request: request).calculate()
                if let firstRoute = directions.routes.first {
                    await MainActor.run {
                        route = firstRoute
                        distance = firstRoute.distance * 3.28084               // feet
                        expectedTravelTime = firstRoute.expectedTravelTime / 60 // convert seconds to minutes
                        routeSteps = firstRoute.steps.filter{!$0.instructions.isEmpty}
                    }
                }
            } catch {
                print("Error getting directions: \(error)")
            }
        }
    }
    
    // Simple toggle function - no sync issues!
    func toggleBuildingAccess(_ building: BuildingReference) {
        buildingManager.toggleBuildingAccess(building)
        objectWillChange.send()
    }
    
    func getBuildingAccessStatus(_ building: BuildingReference) -> Bool {
        buildingManager.getBuildingAccessStatus(building)
    }
}



