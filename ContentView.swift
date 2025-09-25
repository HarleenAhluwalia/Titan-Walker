//
//  mapView.swift
//  Titan Walker
//
//  Created by Ling on 9/6/25.
//
import SwiftUI
import MapKit
import CoreLocation
/****************************/
/**    Founctions         */
/****************************/
//coordinate location of CSUF budlings
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
// All the building info
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
/**   Main map view     */
/****************************/
struct mapView: View {
    
    //Admin login
    @State private var showLogin = false
    @State private var username  = ""
    @State private var password  = ""
    @State private var isLoggedIn = false
    @State private var loggedInUser: String? = nil
    @State private var editorMode = "Write"
    
    //first latitude and longitude is where I have set the location to be(CSUF)
    //second latitude and longitude is how zoomed in the map is
    @State  var cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 33.883121, longitude: -117.886101), latitudinalMeters: 850, longitudinalMeters: 850))
    
    @State private var selectedAnnotation: String? = nil
    @State private var selectedBuilding: Building? = nil
    @State private var showSheet = false
    @State private var route: MKRoute?
    
    //keeps track of user locations and the private node
    let locationManager = CLLocationManager()
   @State private var tappedCoordinate: CLLocationCoordinate2D?
   @State private var pressLocation: CGPoint = .zero
    
    //Put all the buildings in one list
    @State private var buildings: [Building] = [
        .init(name: "Humanities", coordinate: . HUM, nodeType: "none"),
        .init(name: "McCarthy Hall", coordinate: .MH, nodeType: "none"),
        .init(name: "Computer Science", coordinate: .CS, nodeType: "none"),
        .init(name: "Engineering", coordinate: .E, nodeType: "none"),
        .init(name: "Education", coordinate: .EC, nodeType: "none"),
        .init(name: "Kibesiology", coordinate: .KHS, nodeType: "none"),
        .init(name: "Pollak Library", coordinate: .PL, nodeType: "none"),
        .init(name: "Gordon Hall", coordinate: .GH, nodeType: "none"),
        .init(name: "Visual Arts", coordinate: .VA, nodeType: "none"),
        .init(name: "Langsdorf Hall", coordinate: .LH, nodeType: "none"),
        .init(name: "Dan Black Hall", coordinate: .DBH, nodeType: "none"),
        .init(name: "Mihaylo Hall", coordinate: .SGMH, nodeType: "none"),
        .init(name: "College Park", coordinate: .CP, nodeType: "none"),
        .init(name: "Clayes Performing Arts Center", coordinate: .CPAC, nodeType: "none")
        
    ]


    
    @State private var privateNodes: [Building] = [
            .init(name: "Humanities", coordinate: CLLocationCoordinate2D(latitude: 33.880421, longitude: -117.884185), nodeType: "none"),
            .init(name: "McCarthy Hall", coordinate: CLLocationCoordinate2D(latitude: 33.879662, longitude: -117.885496), nodeType: "none"),
            .init(name: "Computer Science", coordinate: CLLocationCoordinate2D(latitude: 33.882372, longitude: -117.882634), nodeType: "none",),
            .init(name: "Engineering", coordinate: CLLocationCoordinate2D(latitude: 33.882263, longitude: -117.883194), nodeType: "none"),
            .init(name: "Education", coordinate: CLLocationCoordinate2D(latitude: 33.881243, longitude: -117.884358), nodeType: "none"),
            .init(name: "Kinesiology", coordinate: CLLocationCoordinate2D(latitude: 33.882819, longitude: -117.8855430), nodeType: "none"),
            .init(name: "Pollak Library", coordinate: CLLocationCoordinate2D(latitude: 33.881555, longitude: -117.885201), nodeType: "none"),
    ]
    
    func colorFor(nodeType: String) -> Color {
            switch nodeType {
            case "outside":
                return Color.blue
            case "inside":
                return Color.green
            default:
                // A fallback color for any other type
                return Color.red
            }
    }
    
    func nodeSave(input: [Building]) {
        print("Saving")
        
    }




    //The initialPosition will only focus the map to where cameraPosition has been set to
    //Annotation is just a pin location of a CSUF building
    var body: some View {
        ZStack {
            // Main Map
            MapReader{ mapProxy in
                Map(initialPosition: cameraPosition) {
                    if(isLoggedIn == false){
                        ForEach(buildings) { building in
                            Annotation(building.name, coordinate: building.coordinate, anchor: .bottom) {
                                
                                VStack(spacing: 4) {
                                    if selectedAnnotation == building.name {
                                        Text(building.name)
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(5)
                                            .shadow(radius: 2)
                                    }
                                    
                                    
                                    //How the pin icon looks
                                    //Check if the user has clicked the pin to show the name
                                    Image(systemName: "building")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .padding(5)
                                        .background(Color.red, in: .circle)
                                        .onTapGesture {
                                            if selectedAnnotation == building.name {
                                                selectedAnnotation = nil
                                                selectedBuilding = nil
                                            } else {
                                                selectedAnnotation = building.name
                                                selectedBuilding = building
                                                showSheet = true
                                            }
                                        }
                                    
                                }// end of Vstack
                            }
                        }// end of ForEach(buildings)
                    }else{
                        ForEach(privateNodes) { building in
                            Annotation(building.name, coordinate: building.coordinate, anchor: .bottom) {
                                VStack(spacing: 4) {
                                    if selectedAnnotation == building.name {
                                        Text(building.name)
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(5)
                                            .shadow(radius: 2)
                                        Text(building.nodeType)
                                    }
                                    
                                    //How the pin icon looks
                                    //Check if the user has clicked the pin to show the name
                                        //.background(building.nodeType == "outside" ? Color.blue : building.nodeType == "none" ? Color.red :, in: .circle)
                                    
                                    Image(systemName: "paperplane.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .padding(5)
                                        .background(colorFor(nodeType: building.nodeType), in: .circle)
                                        .onTapGesture {
                                            if selectedAnnotation == building.name {
                                                selectedAnnotation = nil
                                            } else {
                                                selectedAnnotation = building.name
                                            }
                                        }
                                }
                            }
                            
                        }
                    }
                    
                    UserAnnotation()
                    
                    //Get Directions from one location to another
                    if let route{
                        MapPolyline(route)
                            .stroke(Color.blue, lineWidth: 3)
                    }
                    
                }// end of Map
                .sheet(isPresented: $showSheet) {
                    VStack(spacing: 20) {
                        // Show building name in header, adding the image later
                        if let buildingName = selectedAnnotation {
                            Text(buildingName)
                                .font(.headline)
                                .padding(.top)
                        }
                        
                        Divider()
                        // Action buttons
                        Button {
                            if let destination = selectedBuilding?.coordinate {
                                getDirection(to:destination)
                            }
                        } label: {
                            Label("Get Directions", systemImage: "arrow.turn.down.right")
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding()
                    //Makes it behave like Apple Maps (short, medium, large)
                    .presentationDetents([.height(200), .medium, .large])
                    .presentationDragIndicator(.visible)
                }//end of .sheet(isPresented: $showSheet)
                
                .onAppear {
                    locationManager.requestWhenInUseAuthorization()
                    
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .mapStyle(.imagery(elevation: .realistic))
                
                .onTapGesture (coordinateSpace: .global){ position in
                    if(isLoggedIn == true) {
                        if let coordinate = mapProxy.convert(position, from: .global){
                            tappedCoordinate = coordinate
                            //Text("Tapped at coordinate: \(coordinate.latitude), \(coordinate.longitude)")
                            print("Tapped at coordinate: \(coordinate.latitude), \(coordinate.longitude)")
                            self.pressLocation.x = coordinate.latitude
                            self.pressLocation.y = coordinate.longitude
                            // Optional: Add a new pin where the user tapped
                            //let newPlace = Place(name: "Tapped Location", coordinate: coordinate)
                            let newPlace = Building.init(name: "Tapped Location", coordinate: coordinate, nodeType: "inside")
                            privateNodes.append(newPlace)
                            //exit(1)
                            
                            
                        }
                    }
                    
                }
            }
    
            
            // Settings button overlay
            VStack {
                HStack {
                    Button(action: {
                        showLogin = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    Spacer()
                }
                Spacer()
            }// end of VStack
            .padding()
            
            //CHange this back to true later this is for debugging
            if(isLoggedIn == true) {
                VStack {
                    Text(editorMode + " Mode")
                    if(editorMode == "Edit"){
                        Image(systemName: "pencil")
                            .background(.green)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                            //.frame(width: 10)
                            //.frame(height: 10)
                            //.background(Color.green)
                    } else if(editorMode == "Write") {
                        Image(systemName: "pencil.line")
                            .background(.blue)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                    } else if(editorMode == "Delete") {
                        Image(systemName: "pencil.slash")
                            .background(.red)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                    }
                    Spacer()
                }
                HStack {
                    // This pushes the button to the left
                    VStack(spacing: 10) {
                        Button {
                            // Button action
                            editorMode = "Write"
                        } label: {
                            ZStack {
                                Image(systemName: "pencil.line")
                                    .foregroundColor(.black)
                                //Text("E")
                            }
                        }
                        //.setBackgroundImage(Image(systemName: "paperplane.circle"), for: .normal)
                        .buttonStyle(.bordered)
                        .background(Color.blue)
                        //.frame(maxWidth: 300)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30)
                        .frame(height: 30)
                        .offset(y:130)
                        .offset(x: 5)
                        Text("Write")
                            .offset(y:120)
                            .offset(x: 5)
                        
                        //.cornerRadius(12)
                        //Spacer()
                        // ... other buttons if needed
                        Button {
                            // Button action
                            editorMode = "Edit"
                        } label: {
                            ZStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(.black)
                                //Text("E")
                            }
                        }
                        //.setBackgroundImage(Image(systemName: "paperplane.circle"), for: .normal)
                        .buttonStyle(.bordered)
                        .background(Color.green)
                        //.frame(maxWidth: 300)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30)
                        .frame(height: 30)
                        .offset(y:123)
                        .offset(x: 5)
                        Text("Edit")
                            .offset(y:125)
                            .offset(x: 5)
                        
                        //.cornerRadius(12)
                        
                        
                        Button {
                            // Button action
                            editorMode = "Delete"
                        } label: {
                            ZStack {
                                Image(systemName: "pencil.slash")
                                    .foregroundColor(.black)
                                //Text("E")
                            }
                        }
                        //.setBackgroundImage(Image(systemName: "paperplane.circle"), for: .normal)
                        .buttonStyle(.bordered)
                        .background(Color.red)
                        //.frame(maxWidth: 300)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30)
                        .frame(height: 30)
                        .offset(y:123)
                        .offset(x: 5)
                        Text("Delete")
                            .offset(y:125)
                            .offset(x: 5)
                        
                        //.cornerRadius(12)
                        Spacer()
                    }
                    Spacer()
                    
                }
            }
            
         // Login popup
         if showLogin {
             if(isLoggedIn == false) {
                 VStack(spacing: 12) {
                     Text("Admin Login").font(.headline)
                     TextField("Username", text: $username)
                         .textFieldStyle(RoundedBorderTextFieldStyle())
                         .padding(.horizontal)
                     SecureField("Password", text: $password)
                         .textFieldStyle(RoundedBorderTextFieldStyle())
                         .padding(.horizontal)
                     
                     HStack {
                         Button("Login") {
                             if username == "Admin" && password == "password123" {
                                 print("Login successful")
                                 isLoggedIn = true
                                 loggedInUser = username
                                 username = ""
                                 password = ""
                             } else {
                                 print("Invalid login")
                             }
                             showLogin = false
                         }
                         .buttonStyle(.borderedProminent)
                         
                         Button("Cancel") {
                             showLogin = false
                         }
                         .buttonStyle(.bordered)
                     }
                     
                 }
                 .padding()
                 .background(Color.white)
                 .cornerRadius(12)
                 .shadow(radius: 5)
                 .frame(maxWidth: 300)
             } else {
                 VStack(spacing: 12) {
                     if let user = loggedInUser {
                         Text("Profile")
                             .font(.headline)
                         Text("Username: \(user)")
                             .font(.subheadline)
                             .foregroundColor(.gray)
                     }
                     
                     Divider()
                     
                     Text("Logout?").font(.headline)
                     
                     HStack {
                         Button("Logout") {
                             isLoggedIn = false
                             loggedInUser = nil
                             showLogin = false
                         }
                         .buttonStyle(.borderedProminent)
                         
                         Button("Cancel") {
                             showLogin = false
                         }
                         .buttonStyle(.bordered)
                     }
                     
                 }
                 .padding()
                 .background(Color.white)
                 .cornerRadius(12)
                 .shadow(radius: 5)
                 .frame(maxWidth: 300)
                }// end of if else loop
            }
        }//end of ZStack
    }// end of var body: some View
    
    //Get user location functions
    func getUserLocation() async -> CLLocationCoordinate2D?{
        let updates = CLLocationUpdate.liveUpdates()
        
        do{
            let update = try await updates.first{ $0.location?.coordinate != nil}
                return update?.location?.coordinate
            }catch {
                print("Cannnot get user location")
                return nil
            }
        }
    
    // Get the directions
    // As now it only gets the first walking route it finds
    func getDirection( to destination: CLLocationCoordinate2D){
        Task {
            guard let userLocation = await getUserLocation() else { return}
                
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: userLocation))
            request.destination = MKMapItem(placemark: .init(coordinate: destination))
            request.transportType = .walking
            
            do{
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first
            }catch{
                print("Error getting directions")
            }
        }
    }
}






#Preview {
    mapView()
}





