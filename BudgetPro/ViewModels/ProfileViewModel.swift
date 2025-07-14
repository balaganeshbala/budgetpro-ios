//
//  ProfileViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userName = "User"
    @Published var userEmail = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let supabaseManager = SupabaseManager.shared
    
    func loadUserInfo() {
        guard let user = supabaseManager.currentUser else {
            errorMessage = "No user found"
            return
        }
        
        userEmail = user.email ?? "No email"
        
        // Get full name from user metadata
        if let fullName = user.userMetadata["full_name"]?.stringValue, !fullName.isEmpty {
            userName = fullName
        } else {
            // Fallback to email username
            userName = String(userEmail.split(separator: "@").first ?? "User")
        }
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await supabaseManager.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
