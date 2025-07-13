import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let urlString = config["SupabaseURL"] as? String,
              let url = URL(string: urlString),
              let anonKey = config["SupabaseAnonKey"] as? String else {
            fatalError("Could not load Supabase configuration from Config.plist")
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
        
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task { @MainActor in
            do {
                let session = try await client.auth.session
                self.currentUser = session.user
                self.isAuthenticated = true
            } catch {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    func signUp(email: String, password: String, fullName: String? = nil) async throws {
        var signUpData: [String: AnyJSON] = [:]
        if let fullName = fullName, !fullName.isEmpty {
            signUpData["full_name"] = AnyJSON.string(fullName)
        }
        
        let session = try await client.auth.signUp(
            email: email, 
            password: password,
            data: signUpData
        )
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
}
