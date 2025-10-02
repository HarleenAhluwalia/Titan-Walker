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
// Building info structure
struct Building: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var nodeType: String
}
struct Place: Identifiable {
    let name: String
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
}
/****************************/
/**   Private Variables & State    */
/****************************/
class MapData: ObservableObject {
    // Camera position for map
    @Published var cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 33.883121, longitude: -117.886101), latitudinalMeters: 850, longitudinalMeters: 850))
    
    // Map interaction state
    @Published var selectedAnnotation: UUID? = nil
    @Published var selectedBuilding: Building? = nil
    @Published var showSheet = false
    @Published var route: MKRoute?
    
    // Location tracking
    let locationManager = CLLocationManager()
    @Published var tappedCoordinate: CLLocationCoordinate2D?
    @Published var pressLocation: CGPoint = .zero
    
    // Building data
    @Published var buildings: [Building] = [
        .init(name: "Humanities", coordinate: .HUM, nodeType: "none"),
        .init(name: "McCarthy Hall", coordinate: .MH, nodeType: "none"),
        .init(name: "Computer Science", coordinate: .CS, nodeType: "none"),
        .init(name: "Engineering", coordinate: .E, nodeType: "none"),
        .init(name: "Education", coordinate: .EC, nodeType: "none"),
        .init(name: "Kinesiology", coordinate: .KHS, nodeType: "none"),
        .init(name: "Pollak Library", coordinate:.PL, nodeType: "none"),
        .init(name: "Gordon Hall", coordinate: .GH, nodeType: "none"),
        .init(name: "Visual Arts", coordinate: .VA, nodeType: "none"),
        .init(name: "Langsdorf Hall", coordinate: .LH, nodeType: "none"),
        .init(name: "Dan Black Hall", coordinate: .DBH, nodeType: "none"),
        .init(name: "Mihaylo Hall", coordinate: .SGMH, nodeType: "none"),
        .init(name: "College Park", coordinate: .CP, nodeType: "none"),
        .init(name: "Clayes Performing Arts Center", coordinate: .CPAC, nodeType: "none")
    ]
    
    @Published var privateNodes: [Building] = [
        .init(name: "Mihaylo Hall", coordinate: .SGMH, nodeType: "none"),
        .init(name: "Humanities", coordinate: .HUM, nodeType: "none"),
        .init(name: "McCarthy Hall", coordinate: .MH, nodeType: "none"),
        .init(name: "Computer Science", coordinate: .CS, nodeType: "none"),
        .init(name: "Engineering", coordinate: .E, nodeType: "none"),
        .init(name: "Education", coordinate: .EC, nodeType: "none"),
        .init(name: "Kinesiology", coordinate: .KHS, nodeType: "none"),
        .init(name: "Pollak Library", coordinate: .PL, nodeType: "none"),
        .init(name: "Gordon Hall", coordinate: .GH, nodeType: "none"),
        .init(name: "Visual Arts", coordinate: .VA, nodeType: "none"),
        .init(name: "Langsdorf Hall", coordinate: .LH, nodeType: "none"),
        .init(name: "Dan Black Hall", coordinate: .DBH, nodeType: "none"),
        .init(name: "College Park", coordinate: .CP, nodeType: "none"),
        .init(name: "Clayes Performing Arts Center", coordinate: .CPAC, nodeType: "none")
    ]
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
    
    func nodeSave(input: [Building]) {
        print("Saving")
    }
    
    // Get user location
    func getUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates()
        
        do {
            let update = try await updates.first { $0.location?.coordinate != nil }
            return update?.location?.coordinate
        } catch {
            print("Cannot get user location")
            return nil
        }
    }
    
    // Get directions
    func getDirection(to destination: CLLocationCoordinate2D) {
        Task {
            guard let userLocation = await getUserLocation() else { return }
                
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: userLocation))
            request.destination = MKMapItem(placemark: .init(coordinate: destination))
            request.transportType = .walking
            
            do {
                let directions = try await MKDirections(request: request).calculate()
                await MainActor.run {
                    route = directions.routes.first
                }
            } catch {
                print("Error getting directions")
            }
        }
    }
}



