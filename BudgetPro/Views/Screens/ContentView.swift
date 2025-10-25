import SwiftUI

struct ContentView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Splash Screen
                SplashView()
            } else {
                switch appCoordinator.currentFlow {
                case .loading:
                    SplashView()
                case .authentication:
                    CoordinatedNavigationView {
                        LoginView()
                    }
                case .main:
                    CoordinatedTabView()
                }
            }
        }
        .onChange(of: appCoordinator.isAuthenticated) { _ in
            isLoading = false
        }
        .environmentObject(appCoordinator)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.cardBackground
                .ignoresSafeArea()

            // Loading Indicator
            VStack(spacing: 30) {
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.secondary))
                    .scaleEffect(2.0)
                    .padding(.top, 20)
                
                Text("Loading...")
                    .font(.appFont(16, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .preferredColorScheme(.light)
    }
}
