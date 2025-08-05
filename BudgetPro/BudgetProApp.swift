import SwiftUI

@main
struct BudgetProApp: App {
    init() {
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.white
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        UITabBar.appearance().backgroundColor = UIColor.white
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.secondary)
                .preferredColorScheme(.light)
        }
    }
}
