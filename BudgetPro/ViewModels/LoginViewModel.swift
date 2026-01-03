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
    
    func showSignUp(coordinator: AuthenticationCoordinator? = nil) {
        if let coordinator = coordinator {
            coordinator.navigate(to: .signUp)
        } else {
            showingSignUp = true
        }
    }
    
    func signIn() {
        guard validateForm() else { return }
        
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.signIn(email: email, password: password)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = getErrorMessage(from: error)
            }
        }
    }
    
    func signInWithGoogle() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                try await supabaseManager.signInWithGoogle()
                isLoading = false
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
        let errorMessage = SupabaseManager.shared.getAuthErrorMessage(error: error)
        return errorMessage ?? "Something went wrong! Please try again."
    }
}
