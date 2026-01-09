import SwiftUI

@main
struct BudgetProApp: App {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @StateObject private var appLockVM = AppLockViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure navigation bar appearance for both light and dark modes
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.secondarySystemGroupedBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Ensure tint color adapts to dark mode
        UINavigationBar.appearance().tintColor = UIColor.label
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .tint(Color.primary)
                
                if appLockVM.isLocked {
                    LockedView(viewModel: appLockVM)
                }
            }
            .onOpenURL { url in
                Task {
                    do {
                        try await SupabaseManager.shared.handleAuthCallback(url: url)
                    } catch {
                        print("Auth callback error: \(error)")
                    }
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    if appLockVM.isLocked {
                        appLockVM.checkUnlockPolicy()
                    }
                } else if newPhase == .background || newPhase == .inactive {
                    appLockVM.lock()
                }
            }
        }
    }
}
