//
//  ErrorManager.swift
//  Code combin Titan walker
//
//  Created by Ling on 11/5/25.
//
import SwiftUI
class ErrorManager: ObservableObject {
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var errorTitle = "Error"
    
    func showError(_ message: String, title: String = "Error") {
        errorTitle = title
        errorMessage = message
        showErrorAlert = true
    }
}
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorManager: ErrorManager
    
    func body(content: Content) -> some View {
        content
            .alert(errorManager.errorTitle, isPresented: $errorManager.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorManager.errorMessage)
            }
    }
}
extension View {
    func withErrorHandling(_ errorManager: ErrorManager) -> some View {
        self.modifier(ErrorAlertModifier(errorManager: errorManager))
    }
}



