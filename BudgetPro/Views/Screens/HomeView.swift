import SwiftUI

struct HomeView: View {
    
    @StateObject var viewModel: HomeViewModel
    
    @EnvironmentObject private var coordinator: MainCoordinator
    @State var selectedMonth = Calendar.current.component(.month, from: Date())
    @State var selectedYear = Calendar.current.component(.year, from: Date())

    @State var showingMonthPicker = false
    @State var tempMonth = Calendar.current.component(.month, from: Date())
    @State var tempYear = Calendar.current.component(.year, from: Date())
#if ENABLE_AI_FEATURE
    @State var showingAIChat = false
#endif

    @State private var hasLoadedInitialData = false
    

    
    init(userId: String, repoService: DataFetchRepoService) {
        self._viewModel = StateObject(wrappedValue: HomeViewModel(userId: userId, repoService: repoService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.groupedBackground
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header with profile and month selector
                    headerView
                    
                    // Main content in ScrollView
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Budget Overview Card
                            if viewModel.isLoading {
                                budgetSkeletonCard
                            } else {
                                BudgetOverviewCard(viewModel: viewModel, selectedMonth: selectedMonth, selectedYear: selectedYear)
                            }
                            
                            // Only show other sections if budget exists
                            if !viewModel.isLoading && !viewModel.budgetCategories.isEmpty {
                                // Combined Transactions Section (Expenses/Incomes)
                                TransactionsSectionView(viewModel: viewModel, selectedMonth: selectedMonth, selectedYear: selectedYear)
                                
                                // Options/Features Section
                                optionsSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.refreshData(month: selectedMonth, year: selectedYear)
        }

        .overlay(overlayContent)
#if ENABLE_AI_FEATURE
        .sheet(isPresented: $showingAIChat) {
            aiChatSheet
                .modify {
                    if #available(iOS 16.4, *) {
                        $0.presentationCornerRadius(15)
                    } else {
                        $0
                    }
                }
        }
#endif

        .onAppear {
            // Only load data on first launch
            if !hasLoadedInitialData {
                hasLoadedInitialData = true
                Task {
                    await viewModel.loadData(month: selectedMonth, year: selectedYear)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .expenseDataChanged)) { _ in
            // Only refresh when data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .incomeDataChanged)) { _ in
        // Only refresh when income data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .budgetDataChanged)) { _ in
            // Only refresh when budget data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    

    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Month/Year Selector
                MonthYearPicker(
                    selectedMonth: $selectedMonth,
                    selectedYear: $selectedYear,
                    showingPicker: $showingMonthPicker,
                    onChanged: { month, year in
                        Task {
                            await viewModel.loadData(month: month, year: year)
                        }
                    }
                )
                .onChange(of: showingMonthPicker) { isShowing in
                    if isShowing {
                        tempMonth = selectedMonth
                        tempYear = selectedYear
                    }
                }
                
                Spacer()
                
                // AI Chat Button
                // AI Chat Button removed for App Store submission
#if ENABLE_AI_FEATURE
                Button(action: {
                    showingAIChat = true
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(5)
                }
                .modify {
                    if #available(iOS 26.0, *) {
                        $0.liquidGlass()
                    } else {
                        $0.buttonStyle(.bordered)
                    }
                }
                .modify {
                    if #available(iOS 17.0, *) {
                        $0.buttonBorderShape(.circle)
                    } else {
                        $0.buttonBorderShape(.roundedRectangle)
                    }
                }
#endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            
            Divider()
        }
        .background(Color.cardBackground)
    }
    
    
    // MARK: - Options Section
    private var optionsSection: some View {
        CardView(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quick Actions")
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
                .padding(16)
                
                // Options content
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "chart.pie",
                        iconColor: Color.secondary,
                        backgroundColor: Color.primary.opacity(0.1),
                        title: "Savings Analysis",
                        showChevron: true,
                        action: {
                            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                            let monthString = monthNames[selectedMonth - 1]
                            let yearString = String(selectedYear)
                            
                            coordinator.navigate(to: .savingsAnalysis(
                                expenses: viewModel.recentExpenses,
                                incomes: viewModel.recentIncomes,
                                totalBudget: viewModel.totalBudget,
                                month: monthString,
                                year: yearString
                            ))
                        }
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    SettingsRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: Color.secondary,
                        backgroundColor: Color.primary.opacity(0.1),
                        title: "Monthly Trends",
                        showChevron: true,
                        action: {
                             coordinator.navigate(to: .monthlyTrends)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Skeleton Loading
    private var budgetSkeletonCard: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondarySystemFill)
                        .frame(width: 120, height: 20)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondarySystemFill)
                                .frame(width: 80, height: 16)
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondarySystemFill)
                                .frame(width: 60, height: 16)
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
    

}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    // Simple mock that returns empty or sample data and never hits the network.
    private final class MockDataFetchRepoService: DataFetchRepoService {
        
        func fetchAll<T>(from table: String, filters: [RepoQueryFilter], orderBy: String?) async throws -> [T] where T : Decodable {
            // Simulate small async latency for previews
            try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms
            
            let previewUserId = "preview-user"
            
            // Return concrete arrays only when T matches exactly.
            if T.self == BudgetEntry.self, table == "budget" {
                let result: [BudgetEntry] = [
                    BudgetEntry(id: 1, date: "2025-07-01", category: ExpenseCategory.food.rawValue, amount: 20000, userId: previewUserId),
                    BudgetEntry(id: 2, date: "2025-07-01", category: ExpenseCategory.housing.rawValue, amount: 30000, userId: previewUserId),
                    BudgetEntry(id: 3, date: "2025-07-01", category: ExpenseCategory.travel.rawValue, amount: 10000, userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            if T.self == Expense.self, table == "expenses" {
                let result: [Expense] = [
                    Expense(id: 10, name: "Groceries", amount: 2500, category: .groceries, date: CommonHelpers.parseDate("2025-07-12"), userId: previewUserId),
                    Expense(id: 11, name: "Fuel", amount: 1200, category: .vehicle, date: CommonHelpers.parseDate("2025-07-10"), userId: previewUserId),
                    Expense(id: 12, name: "Dinner", amount: 1800, category: .food, date: CommonHelpers.parseDate("2025-07-08"), userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            if T.self == Income.self, table == "incomes" {
                let result: [Income] = [
                    Income(id: 21, source: "Salary", amount: 60000, category: .salary, date: CommonHelpers.parseDate("2025-07-01"), userId: previewUserId),
                    Income(id: 22, source: "Freelance", amount: 15000, category: .sideHustle, date: CommonHelpers.parseDate("2025-07-08"), userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            // Default empty
            return []
        }
    }
    
    static var previews: some View {
        // Coordinator is required as EnvironmentObject for navigation and repos.
        let coordinator = MainCoordinator(userId: "preview-user")
        let mockRepo = MockDataFetchRepoService()
        
        return Group {
            HomeView(userId: "preview-user", repoService: mockRepo)
                .environmentObject(coordinator)
                .preferredColorScheme(.light)
                .previewDisplayName("Home - Light")
            
            HomeView(userId: "preview-user", repoService: mockRepo)
                .environmentObject(coordinator)
                .preferredColorScheme(.dark)
                .previewDisplayName("Home - Dark")
        }
    }
}
