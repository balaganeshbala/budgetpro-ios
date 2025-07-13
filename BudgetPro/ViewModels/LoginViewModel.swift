import Foundation
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingSignUp = false
    
    // Validation properties
    @Published var emailError = ""
    @Published var passwordError = ""
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Validation Methods
    
    func validateEmail() {
        emailError = ""
        
        if email.isEmpty {
            emailError = "Email is required"
            return
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid email address"
        }
    }
    
    func validatePassword() {
        passwordError = ""
        
        if password.isEmpty {
            passwordError = "Password is required"
            return
        }
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        }
    }
    
    func validateForm() -> Bool {
        validateEmail()
        validatePassword()
        
        return emailError.isEmpty && passwordError.isEmpty
    }
    
    var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        emailError.isEmpty && 
        passwordError.isEmpty &&
        email.contains("@")
    }
    
    // MARK: - Actions
    
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    func showSignUp() {
        showingSignUp = true
    }
    
    func signIn() {
        guard validateForm() else { return }
        
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.signIn(email: email, password: password)
                isLoading = false
                clearForm()
            } catch {
                isLoading = false
                errorMessage = getErrorMessage(from: error)
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        emailError = ""
        passwordError = ""
        errorMessage = ""
    }
    
    private func getErrorMessage(from error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid") && errorString.contains("credentials") {
            return "Invalid email or password. Please check your credentials."
        } else if errorString.contains("network") || errorString.contains("connection") {
            return "Network error. Please check your internet connection."
        } else if errorString.contains("email") && errorString.contains("not found") {
            return "No account found with this email address."
        } else {
            return "Sign in failed. Please try again."
        }
    }
}