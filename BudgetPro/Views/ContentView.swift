import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Splash Screen
                SplashView()
            } else if supabaseManager.isAuthenticated {
                // Main App - Home Screen
                HomeView()
            } else {
                // Authentication - Login Screen
                LoginView()
            }
        }
        .onAppear {
            // Check authentication status
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
            }
        }
        .onChange(of: supabaseManager.isAuthenticated) { _ in
            isLoading = false
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                // App Name
                Text("BudgetPro")
                    .font(.sora(28, weight: .bold))
                    .foregroundColor(.black)
                
                // Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.4, blue: 0.4)))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
