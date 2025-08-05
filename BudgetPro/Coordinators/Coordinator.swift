import SwiftUI
import Combine

@MainActor
protocol Coordinator: ObservableObject {
    associatedtype Route
    
    var navigationPath: NavigationPath { get set }
    
    func navigate(to route: Route)
    func pop()
    func popToRoot()
    func dismiss()
}

@MainActor
class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentFlow: AppFlow = .authentication
    
    private var cancellables = Set<AnyCancellable>()
    
    enum AppFlow {
        case authentication
        case main
    }
    
    init() {
        setupAuthenticationObserver()
    }
    
    private func setupAuthenticationObserver() {
        SupabaseManager.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                self?.currentFlow = isAuthenticated ? .main : .authentication
            }
            .store(in: &cancellables)
    }
    
    func handleDeepLink(url: URL) {
        // Handle deep linking logic here
    }
}