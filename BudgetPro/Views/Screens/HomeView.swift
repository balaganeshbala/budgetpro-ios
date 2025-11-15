import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel: HomeViewModel
    
    @EnvironmentObject private var coordinator: MainCoordinator
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    @State private var showingMonthPicker = false
    @State private var tempMonth = Calendar.current.component(.month, from: Date())
    @State private var tempYear = Calendar.current.component(.year, from: Date())
    @State private var hasLoadedInitialData = false
    
    // New: Tab selection for combined transactions section
    private enum TransactionsTab: String, CaseIterable, Identifiable {
        case expenses = "Expenses"
        case incomes = "Incomes"
        var id: String { rawValue }
    }
    @State private var selectedTransactionsTab: TransactionsTab = .expenses
    
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
                                budgetOverviewCard
                            }
                            
                            // Only show other sections if budget exists
                            if !viewModel.isLoading && !viewModel.budgetCategories.isEmpty {
                                // Combined Transactions Section (Expenses/Incomes)
                                transactionsSection
                                
                                // Options/Features Section
                                optionsSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.refreshData(month: selectedMonth, year: selectedYear)
        }

        .overlay(
            Group {
                if showingMonthPicker {
                    MonthYearPickerDialog(
                        selectedMonth: $tempMonth,
                        selectedYear: $tempYear,
                        isPresented: $showingMonthPicker,
                        months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                        years: Array(2023...Calendar.current.component(.year, from: Date())),
                        onDone: {
                            selectedMonth = tempMonth
                            selectedYear = tempYear
                            Task {
                                await viewModel.loadData(month: tempMonth, year: tempYear)
                            }
                            showingMonthPicker = false
                        }
                    )
                }
            }
        )
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
    
    // MARK: - Combined Transactions Section (Tabbed)
    private var transactionsSection: some View {
        CardView(padding: EdgeInsets(top: 16, leading: 0, bottom: 10, trailing: 0)) {
            VStack(spacing: 16) {
                // Header with segmented control
                VStack(spacing: 12) {
                    HStack {
                        Text("Transactions")
                            .font(.appFont(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                        
                        // Contextual Add button
                        Button {
                            switch selectedTransactionsTab {
                            case .expenses:
                                coordinator.navigate(to: .addExpense)
                            case .incomes:
                                coordinator.navigate(to: .addIncome)
                            }
                        } label: {
                            Label {
                                Text("Add")
                                    .font(.appFont(14, weight: .semibold))
                            } icon: {
                                if #available(iOS 16.0, *) {
                                    Image(systemName: "plus")
                                        .fontWeight(.bold)
                                } else {
                                    Image(systemName: "plus")
                                }
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Segmented control
                    Picker("Transactions", selection: $selectedTransactionsTab) {
                        ForEach(TransactionsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
                
                // Content for selected tab
                VStack(spacing: 0) {
                    if selectedTransactionsTab == .expenses {
                        expensesTabContent
                    } else {
                        incomesTabContent
                    }
                }
            }
        }
    }
    
    // MARK: - Expenses Tab Content
    private var expensesTabContent: some View {
        Group {
            if viewModel.recentExpenses.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 40))
                            .foregroundColor(.secondaryText.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No expenses yet")
                                .font(.appFont(16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("Add your first expense to track spending")
                                .font(.appFont(14))
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addExpense)
                        }) {
                            Text("Add Expense")
                                .font(.appFont(14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.primary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentExpenses.prefix(5).enumerated()), id: \.offset) { index, expense in
                        TransactionRow<Expense, ExpenseDetailsView>(title: expense.name, amount: expense.amount, dateString: expense.dateString, categoryIcon: expense.category.iconName, categoryColor: expense.category.color, iconShape: .roundedRectangle, amountColor: Color.primaryText, showChevron: true) {
                            ExpenseDetailsView(expense: expense, repoService: coordinator.expenseRepo)
                        }
                        
                        if index < min(viewModel.recentExpenses.count - 1, 4) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    VStack {
                        Divider()
                        Button(action: {
                            coordinator.navigate(to: .allExpenses(expenses: viewModel.recentExpenses, month: selectedMonth, year: selectedYear))
                        }) {
                            moreDetailsButton
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Incomes Tab Content
    private var incomesTabContent: some View {
        Group {
            if viewModel.recentIncomes.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondaryText.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No incomes yet")
                                .font(.appFont(16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("Add your income sources to track earnings")
                                .font(.appFont(14))
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addIncome)
                        }) {
                            Text("Add Income")
                                .font(.appFont(14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.primary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentIncomes.prefix(5).enumerated()), id: \.offset) { index, income in
                        TransactionRow<Income, IncomeDetailsView>(title: income.source, amount: income.amount, dateString: income.dateString, categoryIcon: income.category.iconName, categoryColor: income.category.color, iconShape: .roundedRectangle, amountColor: Color.primaryText, showChevron: true) {
                            IncomeDetailsView(income: income, repoSerice: coordinator.incomeRepo)
                        }
                        
                        if index < min(viewModel.recentIncomes.count - 1, 4) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    VStack {
                        Divider()
                        Button(action: {
                            coordinator.navigate(to: .allIncomes(incomes: viewModel.recentIncomes, month: selectedMonth, year: selectedYear))
                        }) {
                            moreDetailsButton
                        }
                    }
                }
            }
        }
    }
    
    private var moreDetailsButton: some View {
        HStack {
            Spacer()
            Text("More Details")
                .font(.appFont(14, weight: .semibold))
                .foregroundColor(Color.primary)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.primary)
            Spacer()
        }
        .padding(16)
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            
            Divider()
        }
        .background(Color.cardBackground)
    }
    
    private var isOverBudget: Bool {
        viewModel.totalSpent > viewModel.totalBudget
    }
    
    private var remainingBudget: Double {
        viewModel.totalBudget - viewModel.totalSpent
    }
    
    private var spentBasedColor: Color {
        isOverBudget ? .adaptiveRed : .primaryText
    }
    
    private var isPastMonth: Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        if selectedYear < currentYear {
            return true
        } else if selectedYear == currentYear && selectedMonth < currentMonth {
            return true
        }
        return false
    }
    
    // MARK: - Budget Overview Card
    @ViewBuilder
    private var budgetOverviewCard: some View {
        if viewModel.budgetCategories.isEmpty {
            // No budget state - show custom empty state
            CardView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Budget")
                            .font(.appFont(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                    }
                    
                    if isPastMonth {
                        // Past month no budget state
                        pastMonthNoBudgetState
                    } else {
                        // Current/future month no budget state
                        currentMonthNoBudgetState
                    }
                }
            }
        } else {
            // Budget exists
            CardView {
                VStack {
                    // Header
                    HStack {
                        
                        Text("Budget")
                            .font(.appFont(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        if (!isPastMonth) {
                            Button(action: {
                                coordinator.navigate(to: .editBudget(budgetCategories: viewModel.budgetCategories, month: selectedMonth, year: selectedYear))
                            }) {
                                Label {
                                    Text("Edit")
                                        .font(.appFont(14, weight: .semibold))
                                } icon: {
                                    if #available(iOS 16.0, *) {
                                        Image(systemName: "pencil")
                                            .fontWeight(.bold)
                                    } else {
                                        Image(systemName: "pencil")
                                    }
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primary.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Remaining Amount - Highlighted at the top
                    VStack(spacing: 0) {
                        Button {
                            coordinator.navigate(to: .budgetCategories(budgetCategories: viewModel.budgetCategories, totalBudget: viewModel.totalBudget, totalSpent: viewModel.totalSpent, expenses: viewModel.recentExpenses, month: selectedMonth, year: selectedYear))
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Group {
                                        Text(isOverBudget ? "Overspent": "Remaining")
                                            .font(.appFont(14, weight: .medium))
                                            .foregroundColor(.secondaryText)
                                        
                                        Text("₹\(CommonHelpers.formatAmount(abs(remainingBudget)))")
                                            .font(.appFont(30, weight: .bold))
                                            .foregroundStyle(spentBasedColor)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Chevron on right side
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondaryText)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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
    
    // MARK: - Past Month No Budget State
    private var pastMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondaryText)
            
            Text("No Budget Data Available")
                .font(.appFont(18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text("Budget data for past months cannot be created. Please select the current month to set a budget.")
                .font(.appFont(14))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 16)
        }
        .padding(.all, 16)
    }
    
    // MARK: - Current Month No Budget State
    private var currentMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.secondaryText.opacity(0.6))
            
            Text("No budget created yet")
                .font(.appFont(16, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Text("Create your budget to track your expenses")
                .font(.appFont(14))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                coordinator.navigate(to: .createBudget(month: selectedMonth, year: selectedYear))
            }) {
                Text("Create Budget")
                    .font(.appFont(14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    // Simple mock that returns empty or sample data and never hits the network.
    private final class MockDataFetchRepoService: DataFetchRepoService {
        
        func fetchAll<T>(from table: String, filters: [RepoQueryFilter]) async throws -> [T] where T : Decodable {
            // Simulate small async latency for previews
            try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms
            
            let previewUserId = "preview-user"
            
            // Return concrete arrays only when T matches exactly.
            if T.self == BudgetResponse.self, table == "budget" {
                let result: [BudgetResponse] = [
                    BudgetResponse(id: 1, category: ExpenseCategory.food.rawValue, amount: 20000, date: "2025-07-01", userId: previewUserId),
                    BudgetResponse(id: 2, category: ExpenseCategory.housing.rawValue, amount: 30000, date: "2025-07-01", userId: previewUserId),
                    BudgetResponse(id: 3, category: ExpenseCategory.travel.rawValue, amount: 10000, date: "2025-07-01", userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            if T.self == ExpenseResponse.self, table == "expenses" {
                let result: [ExpenseResponse] = [
                    ExpenseResponse(id: 10, date: "2025-07-12", name: "Groceries", category: ExpenseCategory.groceries.rawValue, amount: 2500, userId: previewUserId),
                    ExpenseResponse(id: 11, date: "2025-07-10", name: "Fuel", category: ExpenseCategory.vehicle.rawValue, amount: 1200, userId: previewUserId),
                    ExpenseResponse(id: 12, date: "2025-07-08", name: "Dinner", category: ExpenseCategory.food.rawValue, amount: 1800, userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            if T.self == IncomeResponse.self, table == "incomes" {
                let result: [IncomeResponse] = [
                    IncomeResponse(id: 21, source: "Salary", amount: 60000, category: IncomeCategory.salary.rawValue, date: "2025-07-01", userId: previewUserId),
                    IncomeResponse(id: 22, source: "Freelance", amount: 15000, category: IncomeCategory.sideHustle.rawValue, date: "2025-07-08", userId: previewUserId)
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
