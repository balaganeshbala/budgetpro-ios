import SwiftUI

@main
struct BudgetProApp: App {
    init() {
        // Configure navigation bar appearance for both light and dark modes
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
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
            ContentView()
                .tint(Color.secondary)
        }
    }
}
