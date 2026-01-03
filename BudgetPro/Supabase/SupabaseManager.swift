import Foundation
import Supabase
import UIKit.UIApplication

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
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    schema: "public"
                ),
                auth: SupabaseClientOptions.AuthOptions(
                    autoRefreshToken: true
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    headers: ["apikey": anonKey]
                )
            )
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
    
    func signInWithGoogle() async throws {
        let url = try client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: URL(string: "com.googleusercontent.apps.693496673208-a7g528ok23je4ng530koslimpbp1dvg8://login-callback")
        )
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    func getAuthErrorMessage(error: Error) -> String? {
        if let authError = error as? Supabase.AuthError {
            return authError.message
        }
        return nil
    }
    
    func handleAuthCallback(url: URL) async throws {
        _ = try await client.auth.session(from: url)
        checkAuthStatus()
    }
}
