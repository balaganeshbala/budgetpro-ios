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
                case .authentication:
                    CoordinatedNavigationView {
                        LoginView()
                    }
                case .main:
                    CoordinatedTabView()
                }
            }
        }
        .onAppear {
            // Check authentication status
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
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
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.secondary))
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
