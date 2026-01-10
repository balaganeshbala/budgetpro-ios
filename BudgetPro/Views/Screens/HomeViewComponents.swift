import SwiftUI

// MARK: - Budget Overview Card
struct BudgetOverviewCard: View {
    @ObservedObject var viewModel: HomeViewModel
    let selectedMonth: Int
    let selectedYear: Int
    @EnvironmentObject private var coordinator: MainCoordinator
    
    @State private var isbudgetOverviewExpanded: Bool = false
    
    private var isOverBudget: Bool {
        viewModel.totalSpent > viewModel.totalBudget
    }
    
    private var remainingBudget: Double {
        viewModel.totalBudget - viewModel.totalSpent
    }
    
    private var spentBasedColor: Color {
        isOverBudget ? .adaptiveRed : .primaryText
    }
    
    private var percentageSpent: Int {
        Int((viewModel.totalSpent / max(viewModel.totalBudget, 1)) * 100)
    }
    
    private var usageBasedColor: Color {
        isOverBudget ? .adaptiveRed : percentageSpent > 80 ? .warningColor : .adaptiveGreen
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
    
    var body: some View {
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
                VStack(spacing: 16) {
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
                    
                    // Remaining Amount - Highlighted at the top
                    VStack(spacing: 16) {
                        Button {
                            withAnimation {
                                isbudgetOverviewExpanded.toggle()
                            }
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
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondaryText)
                                    .rotationEffect(isbudgetOverviewExpanded ? .degrees(180) : .degrees(0))
                            }
                            .contentShape(Rectangle())
                        }
                        
                        if isbudgetOverviewExpanded {
                            Divider()
                            
                            HStack(spacing: 16) {
                                // Total Budget
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Budget")
                                        .font(.appFont(14))
                                        .foregroundColor(.secondaryText)
                                    
                                    Text("₹\(CommonHelpers.formatAmount(viewModel.totalBudget))")
                                        .font(.appFont(20, weight: .semibold))
                                        .foregroundColor(.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                                    .frame(width: 1, height: 40)
                                
                                // Total Spent
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Spent")
                                        .font(.appFont(14))
                                        .foregroundColor(.secondaryText)
                                    
                                    Text("₹\(CommonHelpers.formatAmount(viewModel.totalSpent))")
                                        .font(.appFont(20, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Budget Usage")
                                        .font(.appFont(14, weight: .medium))
                                        .foregroundColor(.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(percentageSpent)%")
                                        .font(.appFont(16, weight: .bold))
                                        .foregroundColor(isOverBudget ? .adaptiveRed : percentageSpent > 80 ? .warningColor : .adaptiveGreen)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.secondarySystemFill)
                                            .frame(height: 10)
                                            .cornerRadius(5)
                                        
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        usageBasedColor,
                                                        usageBasedColor.opacity(0.8)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: min(geometry.size.width, geometry.size.width * (viewModel.totalSpent / max(viewModel.totalBudget, 1))), height: 10)
                                            .cornerRadius(5)
                                            .animation(
                                                .easeInOut(duration: 0.5),
                                                value: viewModel.totalSpent
                                            )
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Past Month No Budget State
    private var pastMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            
            EmptyDataIndicatorView(icon: "clock.arrow.circlepath",
                                   title: "No Budget Data Available",
                                   bodyText: "Budget data for past months cannot be created. Please select the current month to set a budget.")
        }
    }
    
    // MARK: - Current Month No Budget State
    private var currentMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            EmptyDataIndicatorView(icon: "chart.pie",
                                   title: "No Budget Created Yet",
                                   bodyText: "Create your budget to track your expenses")
            
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
        .padding(.bottom, 20)
    }
}

// MARK: - Transactions Section
struct TransactionsSectionView: View {
    @ObservedObject var viewModel: HomeViewModel
    let selectedMonth: Int
    let selectedYear: Int
    @EnvironmentObject private var coordinator: MainCoordinator
    
    private enum TransactionsTab: String, CaseIterable, Identifiable {
        case expenses = "Expenses"
        case incomes = "Incomes"
        var id: String { rawValue }
    }
    @State private var selectedTransactionsTab: TransactionsTab = .expenses

    var body: some View {
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
                        EmptyDataIndicatorView(icon: "creditcard.circle",
                                               title: "No Expenses Yet",
                                               bodyText: "Add your expense to track spending")
                        
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
                .padding(.bottom, 16)
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
                            coordinator.navigate(to: .allExpenses(budgetCategories: viewModel.budgetCategories,
                                                                    totalBudget: viewModel.totalBudget,
                                                                    expenses: viewModel.recentExpenses,
                                                                    month: selectedMonth,
                                                                    year: selectedYear))
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
                    EmptyDataIndicatorView(icon: "dollarsign.circle",
                                           title: "No Incomes Yet",
                                           bodyText: "Add your income to track earnings")
                    
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
                .padding(.bottom, 16)
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
}

// MARK: - Previews

struct HomeViewComponents_Previews: PreviewProvider {
    
    // Simple mock that returns empty or sample data and never hits the network.
    private final class MockDataFetchRepoService: DataFetchRepoService {
        
        let shouldReturnEmpty: Bool
        
        init(shouldReturnEmpty: Bool = false) {
            self.shouldReturnEmpty = shouldReturnEmpty
        }
        
        func fetchAll<T>(from table: String, filters: [RepoQueryFilter], orderBy: String?) async throws -> [T] where T : Decodable {
            
            if shouldReturnEmpty {
                return []
            }
            
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
        let coordinator = MainCoordinator(userId: "preview-user")
        let mockRepo = MockDataFetchRepoService(shouldReturnEmpty: true)
        let viewModel = HomeViewModel(userId: "preview-user", repoService: mockRepo)
        
        // Populate viewModel with some data for preview
        let _ = Task {
            await viewModel.loadData(month: 7, year: 2025)
        }
        
        return Group {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Budget Overview Preview")
                        .font(.headline)
                    
                    BudgetOverviewCard(viewModel: viewModel, selectedMonth: 1, selectedYear: 2025)
                    
                    BudgetOverviewCard(viewModel: viewModel, selectedMonth: 1, selectedYear: 2026)
                }
                .padding()
            }
            .environmentObject(coordinator)
            .previewDisplayName("Budget Overview")
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Transactions Section Preview")
                        .font(.headline)
                    
                    TransactionsSectionView(viewModel: viewModel, selectedMonth: 7, selectedYear: 2025)
                }
                .padding()
            }
            .environmentObject(coordinator)
            .previewDisplayName("Transactions Section")
            
            EmptyDataIndicatorView(icon: "clock.arrow.circlepath",
                                   title: "No Budget Data Available",
                                   bodyText: "Budget data for past months cannot be created. Please select the current month to set a budget.")
                .previewDisplayName("Empty Data View")
        }
        .padding()
        .background(Color.groupedBackground)
    }
}
