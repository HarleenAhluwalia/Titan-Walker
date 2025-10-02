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
    
    var body: some View {
        ZStack {
            // Main Map
            MapReader { mapProxy in
                Map(initialPosition: mapData.cameraPosition) {
                    if !adminAuth.isLoggedIn {
                        // Regular building annotations
                        ForEach(mapData.buildings) { building in
                            Annotation(building.name, coordinate: building.coordinate, anchor: .bottom) {
                                VStack(spacing: 6) {
                                    if mapData.selectedAnnotation == building.id {
                                        Text(building.name)
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(5)
                                            .shadow(radius: 2)
                                    }
                                    
                                    Image(systemName: "building")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .padding(5)
                                        .background(Color.red, in: .circle)
                                        .onTapGesture {
                                            if mapData.selectedAnnotation == building.id {
                                                mapData.selectedAnnotation = nil
                                                mapData.selectedBuilding = nil
                                            } else {
                                                mapData.selectedAnnotation = building.id
                                                mapData.selectedBuilding = building
                                                mapData.showSheet = true
                                            }
                                        }
                                }
                            }
                        }
                    } else {
                        // Admin private nodes
                        ForEach(mapData.privateNodes) { building in
                            Annotation(building.name, coordinate: building.coordinate, anchor: .bottom) {
                                VStack(spacing: 6) {
                                    if mapData.selectedAnnotation == building.id {
                                        Text(building.name)
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(5)
                                            .shadow(radius: 2)
                                        Text(building.nodeType)
                                    }
                                    
                                    Image(systemName: "paperplane.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .padding(5)
                                        .background(mapData.colorFor(nodeType: building.nodeType), in: .circle)
                                        .onTapGesture {
                                            if mapData.selectedAnnotation == building.id {
                                                mapData.selectedAnnotation = nil
                                                mapData.selectedBuilding = nil
                                            } else {
                                                mapData.selectedAnnotation = building.id
                                                mapData.selectedBuilding = building
                                                mapData.showSheet = true
                                            }
                                        }
                                }
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
                .sheet(isPresented: $mapData.showSheet) {
                    VStack(spacing: 20) {
                        if let building = mapData.selectedBuilding {
                            Text(building.name)
                                .font(.headline)
                                .padding(.top)
                        }
                        
                        Divider()
                        
                        Button {
                            if let destination = mapData.selectedBuilding?.coordinate {
                                mapData.getDirection(to: destination)
                            }
                        } label: {
                            Label("Get Directions", systemImage: "arrow.turn.down.right")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                    }
                    .padding()
                    .presentationDetents([.height(200), .medium, .large])
                    .presentationDragIndicator(.visible)
                }
                .onAppear {
                    mapData.locationManager.requestWhenInUseAuthorization()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .mapStyle(.imagery(elevation: .realistic))
                .onTapGesture(coordinateSpace: .global) { position in
                    if adminAuth.isLoggedIn && adminAuth.editorMode == "Write" {
                        if let coordinate = mapProxy.convert(position, from: .global) {
                            mapData.tappedCoordinate = coordinate
                            print("Tapped at coordinate: \(coordinate.latitude), \(coordinate.longitude)")
                            mapData.pressLocation = CGPoint(x: coordinate.latitude, y: coordinate.longitude)
                            
                            let newPlace = Building(name: "Tapped Location", coordinate: coordinate, nodeType: "outside")
                            mapData.privateNodes.append(newPlace)
                        }
                    }
                }
            }
            
            // Settings button overlay
            VStack {
                HStack {
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
                    Spacer()
                }
                Spacer()
            }
            .padding()
            
            // Admin editor controls
            AdminEditorControls(adminAuth: adminAuth)
            
            // Login popup
            LoginPopup(adminAuth: adminAuth)
        }
    }
}
#Preview {
    mapView()
}



