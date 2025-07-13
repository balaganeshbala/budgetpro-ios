import Foundation
import SwiftUI

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    // Validation properties
    @Published var fullNameError = ""
    @Published var emailError = ""
    @Published var passwordError = ""
    @Published var confirmPasswordError = ""
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Validation Methods
    
    func validateFullName() {
        fullNameError = ""
        
        if fullName.isEmpty {
            fullNameError = "Full name is required"
            return
        }
        
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            fullNameError = "Please enter your full name"
        }
    }
    
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
        
        var errors: [String] = []
        
        if password.count < 8 {
            errors.append("at least 8 characters")
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("one uppercase letter")
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("one lowercase letter")
        }
        
        if !password.contains(where: { $0.isNumber }) {
            errors.append("one number")
        }
        
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            errors.append("one special character")
        }
        
        if !errors.isEmpty {
            passwordError = "Password must contain " + errors.joined(separator: ", ")
        }
    }
    
    func validateConfirmPassword() {
        confirmPasswordError = ""
        
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
            return
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        }
    }
    
    func validateForm() -> Bool {
        validateFullName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        
        return fullNameError.isEmpty && emailError.isEmpty && passwordError.isEmpty && confirmPasswordError.isEmpty
    }
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty &&
        fullNameError.isEmpty &&
        emailError.isEmpty && 
        passwordError.isEmpty && 
        confirmPasswordError.isEmpty &&
        email.contains("@") && 
        password == confirmPassword &&
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    // Password strength indicator
    var passwordStrength: PasswordStrength {
        if password.isEmpty { return .none }
        
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { score += 1 }
        
        switch score {
        case 0...1: return .weak
        case 2...3: return .medium
        case 4...5: return .strong
        default: return .none
        }
    }
    
    var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(
                text: "At least 8 characters",
                isMet: password.count >= 8
            ),
            PasswordRequirement(
                text: "One uppercase letter",
                isMet: password.contains(where: { $0.isUppercase })
            ),
            PasswordRequirement(
                text: "One lowercase letter",
                isMet: password.contains(where: { $0.isLowercase })
            ),
            PasswordRequirement(
                text: "One number",
                isMet: password.contains(where: { $0.isNumber })
            ),
            PasswordRequirement(
                text: "One special character",
                isMet: password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
            )
        ]
    }
    
    // MARK: - Actions
    
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        isConfirmPasswordVisible.toggle()
    }
    
    func signUp() async -> Bool {
        guard validateForm() else { return false }
        
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        do {
            try await supabaseManager.signUp(email: email, password: password, fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines))
            isLoading = false
            successMessage = "Account created successfully! Please check your email to verify your account."
            clearForm()
            return true
        } catch {
            isLoading = false
            errorMessage = getErrorMessage(from: error)
            return false
        }
    }
    
    private func clearForm() {
        fullName = ""
        email = ""
        password = ""
        confirmPassword = ""
        fullNameError = ""
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        errorMessage = ""
    }
    
    private func getErrorMessage(from error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("email") && errorString.contains("already") {
            return "An account with this email already exists. Please try signing in instead."
        } else if errorString.contains("weak") && errorString.contains("password") {
            return "Password is too weak. Please choose a stronger password."
        } else if errorString.contains("network") || errorString.contains("connection") {
            return "Network error. Please check your internet connection."
        } else if errorString.contains("invalid") && errorString.contains("email") {
            return "Please enter a valid email address."
        } else {
            return "Account creation failed. Please try again."
        }
    }
}

// MARK: - Supporting Types

enum PasswordStrength {
    case none, weak, medium, strong
    
    var color: Color {
        switch self {
        case .none: return .clear
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var text: String {
        switch self {
        case .none: return ""
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

struct PasswordRequirement {
    let text: String
    let isMet: Bool
}