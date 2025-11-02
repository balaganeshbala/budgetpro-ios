# Budget Pro iOS

**Budget Pro** App is a comprehensive personal finance application designed fully in native iOS to help users manage budgets, track expenses, incomes, and major expenses, and analyze savings. It integrates with a cloud backend for persistence and authentication, and applies a consistent, adaptive UI theme.

## Technology Stack

- **Frontend:** Swift, SwiftUI (+ UIKit for navigation bar appearance), SFSymbols
- **Architecture:** MVVM + Coordinator pattern, `NavigationStack` with `NavigationPath`
- **Backend & Database:** Supabase (Auth + Database/PostgreSQL) via Supabase Swift SDK
- **State Management:** SwiftUI state containers (`@StateObject`, `@EnvironmentObject`), `ObservableObject`-based coordinators and view models, `@Published` properties
- **Platform:** iOS
