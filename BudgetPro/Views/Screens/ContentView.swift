import SwiftUI

struct ContentView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Splash Screen
                SplashView()
            } else if appCoordinator.currentUserId == nil {
                CoordinatedNavigationView {
                    LoginView()
                }
            } else {
                switch appCoordinator.currentFlow {
                case .loading:
                    SplashView()
                case .authentication:
                    CoordinatedNavigationView {
                        LoginView()
                    }
                case .main:
                    CoordinatedTabView(userId: appCoordinator.currentUserId!)
                }
            }
        }
        .onChange(of: appCoordinator.currentFlow) { _ in
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

            LoadingView(titleText: "Loading...")
        }
    }
}

struct ContentViewLight_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .preferredColorScheme(.light)
    }
}

struct ContentViewDark_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .preferredColorScheme(.dark)
    }
}
