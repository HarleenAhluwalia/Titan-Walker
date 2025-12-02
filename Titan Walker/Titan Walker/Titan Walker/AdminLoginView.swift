//
//  AdminLoginView.swift
//  Titan Walker
//
//  Created by Ling on 9/6/25.
//
import SwiftUI
import CoreLocation
import Foundation
/****************************/
/**   Admin Authentication    */
/****************************/
class AdminAuth: ObservableObject {
    
    @Published var showLogin = false
    @Published var username = ""
    @Published var password = ""
    @Published var isLoggedIn = false
    @Published var loggedInUser: String? = nil
    @Published var editorMode = "Write"
    
    func login(errorManager: ErrorManager) {
        if username == "Admin" && password == "password123" {
            print("Login successful")
            isLoggedIn = true
            loggedInUser = username
            username = ""
            password = ""
        } else {
            print("Invalid login")
            errorManager.showError("Invalid username or password", title: "Login Failed")
        }
        showLogin = false
    }
    
    func logout() {
        isLoggedIn = false
        loggedInUser = nil
        showLogin = false
    }
    
    func setEditorMode(_ mode: String) {
        editorMode = mode
    }
    
    func toggleBuildingAccess(_ building: BuildingReference, mapData: MapData, errorManager: ErrorManager) {
        print("DEBUG: Toggling building access for \(building.name)")
        
        // Use the centralized method
        mapData.toggleBuildingAccess(building)
        
        // Get updated status from the source of truth
        if let updatedBuilding = mapData.buildingManager.getBuilding(by: building.id) {
            let newStatus = updatedBuilding.isAccessible ? "open" : "closed"
            print("\(building.name) is now \(newStatus)")
        }
    }
}
/****************************/
/**   Login UI Components    */
/****************************/
struct LoginPopup: View {
    @ObservedObject var adminAuth: AdminAuth
    @ObservedObject var errorManager: ErrorManager
    
    var body: some View {
        if adminAuth.showLogin {
            if !adminAuth.isLoggedIn {
                // Login form
                VStack(spacing: 12) {
                    Text("Admin Login").font(.headline)
                    TextField("Username", text: $adminAuth.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.8))
                    SecureField("Password", text: $adminAuth.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Login") {
                            adminAuth.login(errorManager: errorManager)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            adminAuth.showLogin = false
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
                // Profile/Logout view
                VStack(spacing: 12) {
                    if let user = adminAuth.loggedInUser {
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
                            adminAuth.logout()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            adminAuth.showLogin = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .frame(maxWidth: 300)
            }
        }
    }
}
/****************************/
/**   Admin Editor Controls    */
/****************************/
struct AdminEditorControls: View {
    @ObservedObject var adminAuth: AdminAuth
    
    var body: some View {
        if adminAuth.isLoggedIn {
            VStack {
                // Editor mode indicator
                VStack {
                    Text(adminAuth.editorMode + " Mode")
                    if adminAuth.editorMode == "Edit" {
                        Image(systemName: "pencil")
                            .background(.green)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                    } else if adminAuth.editorMode == "Write" {
                        Image(systemName: "pencil.line")
                            .background(.blue)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                    } else if adminAuth.editorMode == "Delete" {
                        Image(systemName: "pencil.slash")
                            .background(.red)
                            .buttonStyle(.bordered)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .controlSize(.large)
                    }
                    Spacer()
                }
                
                // Editor mode buttons
                HStack {
                    VStack(spacing: 10) {
                        // Write button
                        Button {
                            adminAuth.setEditorMode("Write")
                        } label: {
                            Image(systemName: "pencil.line")
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.bordered)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30, height: 30)
                        
                        Text("Write")
                        
                        // Edit button
                        Button {
                            adminAuth.setEditorMode("Edit")
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.bordered)
                        .background(Color.green)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30, height: 30)
                        
                        Text("Edit")
                        
                        // Delete button
                        Button {
                            adminAuth.setEditorMode("Delete")
                        } label: {
                            Image(systemName: "pencil.slash")
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.bordered)
                        .background(Color.red)
                        .cornerRadius(12)
                        .controlSize(.mini)
                        .frame(width: 30, height: 30)
                        
                        Text("Delete")
                        
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.top, 130)
                    Spacer()
                }
            }
        }
    }
}
/****************************/
/**   Edit Building Popup    */
/****************************/
struct EditBuildingPopup: View {
    let building: BuildingReference
    let adminAuth: AdminAuth
    @ObservedObject var mapData: MapData
    let errorManager: ErrorManager
    let onDismiss: () -> Void
    
    // Get the current accessibility status directly from the building reference
    private var isCurrentlyAccessible: Bool {
        building.isAccessible
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Building")
                .font(.headline)
            
            Text(building.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Set Building Access:")
                .font(.subheadline)
            
            HStack(spacing: 20) {
                Button("Open") {
                    // Only toggle if currently closed
                    if !isCurrentlyAccessible {
                        adminAuth.toggleBuildingAccess(building, mapData: mapData, errorManager: errorManager)
                    }
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isCurrentlyAccessible) // Disable if already open
                
                Button("Closed") {
                    // Only toggle if currently open
                    if isCurrentlyAccessible {
                        adminAuth.toggleBuildingAccess(building, mapData: mapData, errorManager: errorManager)
                    }
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!isCurrentlyAccessible) // Disable if already closed
            }
            
            // Show current status
            Text("Current status: \(isCurrentlyAccessible ? "Open" : "Closed")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .frame(maxWidth: 300)
    }
}



