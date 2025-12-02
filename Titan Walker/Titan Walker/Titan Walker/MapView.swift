//
//  MapView.swift
//  Titan Walker
//
//  Created by Ling on 9/6/25.
//
import SwiftUI
import MapKit
import CoreLocation
import Foundation
/****************************/
/**   Main Map View    */
/****************************/
struct mapView: View {
    @StateObject private var mapData = MapData()
    @StateObject private var adminAuth = AdminAuth()
    
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showDirectionsSheet = false
    @State private var showEditPopup = false
    @State private var selectedBuildingForEdit: BuildingReference? = nil
    
    //Error message
    @StateObject private var errorManager = ErrorManager()
    
    // Single computed property for buildings
    private var displayedBuildings: [BuildingReference] {
        adminAuth.isLoggedIn ? mapData.buildingManager.allBuildings : mapData.buildingManager.accessibleBuildings
    }
    
    var body: some View {
        ZStack {
            // Main Map
            MapReader { mapProxy in
                Map(initialPosition: mapData.cameraPosition, selection: $mapData.selectedAnnotation) {
                    // Simplified annotation logic
                    ForEach(displayedBuildings) { building in
                        Annotation(building.name, coordinate: building.coordinate, anchor: .bottom) {
                            BuildingAnnotationView(
                                building: building,
                                isSelected: mapData.selectedAnnotation == building.id,
                                isAdmin: adminAuth.isLoggedIn
                            )
                            .onTapGesture {
                                handleBuildingTap(building)
                            }
                        }
                    }
                    
                    UserAnnotation()
                    
                    // Route display
                    if let route = mapData.route {
                        MapPolyline(route)
                            .stroke(Color.blue, lineWidth: 3)
                    }
                }
                .onChange(of: mapData.selectedAnnotation) { oldValue, newValue in
                    // Only handle selection changes for regular users or when not in admin edit mode
                    if !adminAuth.isLoggedIn || (adminAuth.isLoggedIn && adminAuth.editorMode == "Write") {
                        if let selectedId = newValue {
                            if let building = displayedBuildings.first(where: { $0.id == selectedId }) {
                                handleBuildingSelection(building)
                            }
                        }
                    }
                }
                .sheet(isPresented: $mapData.showSheet) {
                    BuildingDetailSheet(mapData: mapData, errorManager: errorManager)
                }
                .onAppear {
                    mapData.locationManager.requestWhenInUseAuthorization()
                    mapData.startLocationTracking()
                }
                .onDisappear {
                    mapData.stopLocationTracking()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .mapStyle(.imagery(elevation: .realistic))
                .onTapGesture(coordinateSpace: .global) { position in
                    guard adminAuth.isLoggedIn else { return }
                                        
                    if let coordinate = mapProxy.convert(position, from: .global) {
                        switch adminAuth.editorMode {
                        case "Write":
                            // Add a new building at tap location - DEFAULT TO CLOSED
                            let newBuilding = BuildingReference(
                                name: "New Building",
                                coordinate: coordinate,
                                nodeType: "outside",
                                isAccessible: false  // DEFAULT TO CLOSED
                            )
                            mapData.buildingManager.addBuilding(newBuilding)
                            print("Added node at: \(coordinate.latitude), \(coordinate.longitude)")
                            
                            // FIX: Force immediate UI refresh by updating camera position
                            withAnimation(.easeInOut(duration: 0.3)) {
                                mapData.cameraPosition = .region(.init(
                                    center: coordinate,
                                    latitudinalMeters: 300,
                                    longitudinalMeters: 300
                                ))
                            }
                            
                        default:
                            break
                        }
                    }
                }
            }
            // Overlay for settings + search
            VStack {
                HStack(spacing: 10) {
                    // Settings button
                    Button(action: {
                        adminAuth.showLogin = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                            .foregroundStyle(.black)
                    }
                    // Search button
                    Button(action: {
                        showSearch.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                            .foregroundStyle(.black)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
            
            // Search popup (white box) near top-left
            if showSearch {
                VStack(spacing: 12) {
                    Text("Search Building")
                        .font(.headline)
                    
                    TextField("Type as Humanities or HUM", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Go") {
                            searchBuilding()
                            showSearch = false
                            searchText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            showSearch = false
                            searchText = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .frame(maxWidth: 300)
                .padding(.top, 60)
                .padding(.leading, 10)
                .transition(.scale)
            }
            
            // Admin editor controls
            AdminEditorControls(adminAuth: adminAuth)
            
            // Login popup
            LoginPopup(adminAuth: adminAuth, errorManager: errorManager)
            
            // Edit Building Popup
            if showEditPopup, let building = selectedBuildingForEdit {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showEditPopup = false
                        selectedBuildingForEdit = nil
                    }
                
                EditBuildingPopup(
                    building: building,
                    adminAuth: adminAuth,
                    mapData: mapData,
                    errorManager: errorManager,
                    onDismiss: {
                        showEditPopup = false
                        selectedBuildingForEdit = nil
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        //Error message alert
        .withErrorHandling(errorManager)
        .environmentObject(errorManager)
        .animation(.easeInOut(duration: 0.3), value: showEditPopup)
    }
    
    private func searchBuilding() {
        if let building = displayedBuildings.first(where: {
            $0.name.lowercased().contains(searchText.lowercased())
        }) {
            mapData.selectedAnnotation = building.id
            mapData.cameraPosition = .region(.init(center: building.coordinate, latitudinalMeters: 200, longitudinalMeters: 200))
            
            // Start directions automatically
            mapData.getDirection(to: building.coordinate, errorManager: errorManager, isAdmin: adminAuth.isLoggedIn)
        } else {
            // Check if building exists but is closed for regular users
            if !adminAuth.isLoggedIn {
                let allBuildings = mapData.buildingManager.allBuildings
                let buildingExistsButClosed = allBuildings.contains(where: {
                    $0.name.lowercased().contains(searchText.lowercased()) && !$0.isAccessible
                })
                
                if buildingExistsButClosed {
                    errorManager.showError("\(searchText) is currently closed and inaccessible.")
                    return
                }
            }
            
            errorManager.showError("Building '\(searchText)' not found. Please try another name.")
        }
    }
    
    private func handleBuildingSelection(_ building: BuildingReference) {
        // For regular users, don't select closed buildings
        if !adminAuth.isLoggedIn && !building.isAccessible {
            errorManager.showError("This building is currently closed and inaccessible.")
            mapData.selectedAnnotation = nil
            mapData.selectedBuilding = nil
            return
        }
        
        mapData.selectedBuilding = building
        
        // Only show sheet for regular users
        if !adminAuth.isLoggedIn {
            mapData.showSheet = true
        }
        
        // Auto-center map on selected building
        withAnimation(.easeInOut(duration: 0.5)) {
            mapData.cameraPosition = .region(.init(
                center: building.coordinate,
                latitudinalMeters: 300,
                longitudinalMeters: 300
            ))
        }
    }
    
    private func handleBuildingTap(_ building: BuildingReference) {
        // For regular users, don't allow tapping closed buildings
        if !adminAuth.isLoggedIn && !building.isAccessible {
            errorManager.showError("This building is currently closed and inaccessible.")
            return
        }
        
        // CHECK IF IN EDIT MODE
        if adminAuth.isLoggedIn && adminAuth.editorMode == "Edit" {
            // EDIT MODE: Show edit popup immediately
            selectedBuildingForEdit = building
            showEditPopup = true
            
            // Clear any existing selection to prevent visual conflict
            mapData.selectedAnnotation = nil
            mapData.selectedBuilding = nil
            
            print("DEBUG: Edit mode - showing popup for \(building.name)")
            
        }
        // CHECK IF IN DELETE MODE
        else if adminAuth.isLoggedIn && adminAuth.editorMode == "Delete" {
            // DELETE MODE: Remove the tapped building immediately
            mapData.buildingManager.removeBuilding(building)
            
            // Clear selection
            mapData.selectedAnnotation = nil
            mapData.selectedBuilding = nil
            
            print("DEBUG: Delete mode - removed \(building.name)")
            
        } else {
            // NORMAL MODE: Use the selection system (for regular users or admin in Write mode)
            if mapData.selectedAnnotation == building.id {
                // Deselect if already selected
                mapData.selectedAnnotation = nil
                mapData.selectedBuilding = nil
            } else {
                // Select new building
                mapData.selectedAnnotation = building.id
                mapData.selectedBuilding = building
                
                // Only show sheet for regular users
                if !adminAuth.isLoggedIn {
                    mapData.showSheet = true
                }
            }
        }
    }
}
/****************************/
/**   Building Annotation View    */
/****************************/
struct BuildingAnnotationView: View {
    @ObservedObject var building: BuildingReference
    let isSelected: Bool
    let isAdmin: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            if isSelected {
                VStack(spacing: 2) {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(5)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(4)
                        .shadow(radius: 2)
                    
                    if isAdmin {
                        Text(building.nodeType)
                            .font(.caption)
                            .padding(5)
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                    
                    // Add accessibility status for admin
                    if isAdmin {
                        Text(building.isAccessible ? "Open" : "Closed")
                            .font(.caption2)
                            .padding(3)
                            .background(building.isAccessible ? Color.green : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                }
            }
            
            Image(systemName: isAdmin ? "paperplane.circle" : "building.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.white)
                .frame(width: isSelected ? 28 : 24, height: isSelected ? 28 : 24)
                .padding(6)
                .background(
                    Circle()
                        .fill(annotationColor)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                )
                .overlay(
                    // Add slash for closed buildings
                    !building.isAccessible ?
                    Image(systemName: "slash.circle")
                        .foregroundColor(.black)
                        .font(.system(size: 25))
                        .offset(x: 8, y: -8)
                    : nil
                )
        }
    }
    
    private var annotationColor: Color {
        if isAdmin {
            switch building.nodeType {
            case "outside": return .blue
            case "inside": return .green
            default: return .red
            }
        } else {
            if !building.isAccessible {
                return .gray // Show closed buildings as gray for regular users
            }
            return isSelected ? .blue : .red
        }
    }
}
/****************************/
/**   Building Detail Sheet    */
/****************************/
struct BuildingDetailSheet: View {
    @ObservedObject var mapData: MapData
    @ObservedObject var errorManager: ErrorManager
    @State private var showDirectionsSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let building = mapData.selectedBuilding {
                Text(building.name)
                    .font(.headline)
                    .padding(.top)
                
                // Show closed status prominently
                if !building.isAccessible {
                    VStack {
                        Text("🚫 CLOSED")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("This building is currently inaccessible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let route = mapData.route {
                    Text("Route is active - will auto-update as you move")
                        .font(.caption)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                    
                    Text("Distance: \(Int(mapData.distance)) feet")
                        .font(.subheadline)
                    Text("Expected Travel Time: \(Int(mapData.expectedTravelTime)) min")
                        .font(.subheadline)
                    
                    Button {
                        showDirectionsSheet.toggle()
                    } label: {
                        Label("View Turn-by-Turn Directions", systemImage: "list.bullet")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!building.isAccessible)
                }
            }
            
            Divider()
            
            Button {
                if let destination = mapData.selectedBuilding?.coordinate,
                   let building = mapData.selectedBuilding {
                    
                    // Final safety check - building must be accessible
                    guard building.isAccessible else {
                        errorManager.showError("This building is currently closed and inaccessible.")
                        return
                    }
                    
                    mapData.getDirection(to: destination, errorManager: errorManager, isAdmin: false)
                }
            } label: {
                Label("Get Directions", systemImage: "arrow.turn.down.right")
            }
            .buttonStyle(.borderedProminent)
            .disabled(mapData.selectedBuilding?.isAccessible == false)
            
            if mapData.route != nil {
                Button {
                    mapData.route = nil
                    mapData.stopLocationTracking()
                    mapData.distance = 0
                    mapData.expectedTravelTime = 0
                } label: {
                    Label("Clear Route", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(300), .medium, .large])
        .presentationDragIndicator(.visible)
        
        .sheet(isPresented: $showDirectionsSheet) {
            DirectionsSheet(mapData: mapData)
                .presentationDetents([.fraction(0.35), .medium])
                .presentationDragIndicator(.visible)
        }
    }
}
struct DirectionsSheet: View {
    @ObservedObject var mapData: MapData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Turn-by-Turn Directions")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
            
            if mapData.routeSteps.isEmpty {
                Text("No directions available.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(mapData.routeSteps.enumerated()), id: \.offset) { index, step in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("-> \(step.instructions)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                if step.distance > 0 {
                                    Text("\(Int(step.distance * 3.28084)) feet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 250)
            }
            
            Spacer()
        }
        .padding(.top)
    }
}
#Preview {
    mapView()
}



