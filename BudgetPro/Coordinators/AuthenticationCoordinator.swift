import SwiftUI

@MainActor
class AuthenticationCoordinator: Coordinator {
    @Published var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case login
        case signUp
    }
    
    func navigate(to route: Route) {
        switch route {
        case .login:
            navigationPath.removeLast(navigationPath.count)
        case .signUp:
            navigationPath.append(route)
        }
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func dismiss() {
        pop()
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .login:
            LoginView()
                .environmentObject(self)
        case .signUp:
            SignUpView()
                .environmentObject(self)
        }
    }
}