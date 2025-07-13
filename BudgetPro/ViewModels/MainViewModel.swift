import Foundation
import SwiftUI
import Supabase

@MainActor
class MainViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingSignOutAlert = false
    
    private let supabaseManager = SupabaseManager.shared
    
    var currentUser: User? {
        supabaseManager.currentUser
    }
    
    var userEmail: String {
        currentUser?.email ?? "User"
    }
    
    var userDisplayName: String {
        if let anyJSON = currentUser?.userMetadata["full_name"] as? AnyJSON,
           let name = anyJSON.stringValue {
            return name
        }
        return "User"
    }
    
    // MARK: - Actions
    
    func showSignOutAlert() {
        showingSignOutAlert = true
    }
    
    func signOut() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await supabaseManager.signOut()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to sign out. Please try again."
            }
        }
    }
    
    func dismissError() {
        errorMessage = ""
    }
}
