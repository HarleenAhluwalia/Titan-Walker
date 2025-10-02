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
    
    func login() {
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
    
    func logout() {
        isLoggedIn = false
        loggedInUser = nil
        showLogin = false
    }
    
    func setEditorMode(_ mode: String) {
        editorMode = mode
    }
}
/****************************/
/**   Login UI Components    */
/****************************/
struct LoginPopup: View {
    @ObservedObject var adminAuth: AdminAuth
    
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
                            adminAuth.login()
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

