import SwiftUI

struct CoordinatedNavigationView<Content: View>: View {
    @StateObject private var coordinator = AuthenticationCoordinator()
    let content: () -> Content
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            content()
                .navigationDestination(for: AuthenticationCoordinator.Route.self) { route in
                    coordinator.view(for: route)
                }
        }
        .environmentObject(coordinator)
    }
}

struct CoordinatedTabView: View {
    @StateObject private var coordinator = MainCoordinator()
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            NavigationStack(path: $coordinator.homeNavigationPath) {
                coordinator.view(for: .home)
                    .navigationDestination(for: MainCoordinator.Route.self) { route in
                        coordinator.view(for: route)
                    }
            }
            .tabItem {
                Image(systemName: MainCoordinator.Tab.home.icon)
                Text(MainCoordinator.Tab.home.title)
            }
            .tag(MainCoordinator.Tab.home)
            
            NavigationStack(path: $coordinator.profileNavigationPath) {
                coordinator.view(for: .profile)
                    .navigationDestination(for: MainCoordinator.Route.self) { route in
                        coordinator.view(for: route)
                    }
            }
            .tabItem {
                Image(systemName: MainCoordinator.Tab.profile.icon)
                Text(MainCoordinator.Tab.profile.title)
            }
            .tag(MainCoordinator.Tab.profile)
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            coordinator.sheet(for: sheet)
        }
        .environmentObject(coordinator)
    }
}
