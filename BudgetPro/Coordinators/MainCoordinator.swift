import SwiftUI

@MainActor
class MainCoordinator: Coordinator {
    @Published var navigationPath = NavigationPath()
    @Published var homeNavigationPath = NavigationPath()
    @Published var profileNavigationPath = NavigationPath()
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: Sheet?
    
    let userId: String
    let expenseRepo: TransactionRepoService
    let incomeRepo: TransactionRepoService
    let dataFetchRepo: DataFetchRepoService

    lazy var majorExpenseRepo: TransactionRepoService = {
        SupabaseTransactionRepoService(transactionType: .majorExpense)
    }()
    
    private lazy var financialGoalRepo: FinancialGoalRepoService = {
        SupabaseFinancialGoalRepoService()
    }()
    
    init(userId: String) {
        self.userId = userId
        self.dataFetchRepo = SupabaseDataFetchRepoService()
        self.expenseRepo = SupabaseTransactionRepoService(transactionType: .expense)
        self.incomeRepo = SupabaseTransactionRepoService(transactionType: .income)
    }
    
    enum Tab: CaseIterable {
        case home
        case profile
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .profile: return "person"
            }
        }
    }
    
    enum Route: Hashable {
        case home
        case profile
        case addExpense
        case addIncome
        case createBudget(month: Int, year: Int)
        case editBudget(budgetCategories: [BudgetCategory], month: Int, year: Int)
        case expenseDetails(expense: Expense)
        case incomeDetails(income: Income)
        case allExpenses(budgetCategories: [BudgetCategory], totalBudget: Double, expenses: [Expense], month: Int, year: Int)
        case allIncomes(incomes: [Income], month: Int, year: Int)
        case allMajorExpenses
        case addMajorExpense
        case majorExpenseDetails(majorExpense: MajorExpense)
        case categoryDetail(category: BudgetCategory, expenses: [Expense], month: Int, year: Int)
        case savingsAnalysis(expenses: [Expense], incomes: [Income], totalBudget: Double, month: String, year: String)
        case about
        case financialGoals
        case addFinancialGoal
        case financialGoalDetails(goal: FinancialGoal)
        case editFinancialGoal(goal: FinancialGoal)
        case addContribution(goalId: UUID, goalTitle: String)
        case editContribution(goalId: UUID, goalTitle: String, contribution: GoalContribution)
        case monthlyTrends
        case settings
    }
    
    enum Sheet: Identifiable {
        case profile
        
        var id: String {
            switch self {
            case .profile: return "profile"
            }
        }
    }
    
    func navigate(to route: Route) {
        switch route {
        case .home:
            selectedTab = .home
            homeNavigationPath.removeLast(homeNavigationPath.count)
            profileNavigationPath.removeLast(profileNavigationPath.count)
        case .profile:
            presentedSheet = .profile
        case .addExpense, .addIncome:
            homeNavigationPath.append(route)
        case .allMajorExpenses:
            selectedTab = .profile
            profileNavigationPath.append(route)
        case .addMajorExpense, .majorExpenseDetails, .financialGoals, .addFinancialGoal, .financialGoalDetails, .editFinancialGoal, .addContribution, .editContribution, .settings:
            profileNavigationPath.append(route)
        default:
            // Use the appropriate navigation path based on current tab
            if selectedTab == .profile {
                profileNavigationPath.append(route)
            } else {
                homeNavigationPath.append(route)
            }
        }
    }
    
    func pop() {
        if selectedTab == .profile {
            guard !profileNavigationPath.isEmpty else { return }
            profileNavigationPath.removeLast()
        } else {
            guard !homeNavigationPath.isEmpty else { return }
            homeNavigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        if selectedTab == .profile {
            profileNavigationPath.removeLast(profileNavigationPath.count)
        } else {
            homeNavigationPath.removeLast(homeNavigationPath.count)
        }
    }
    
    func dismiss() {
        if presentedSheet != nil {
            presentedSheet = nil
        } else {
            pop()
        }
    }
    
    func selectTab(_ tab: Tab) {
        selectedTab = tab
        // Don't clear navigation paths when switching tabs
        // This allows each tab to maintain its own navigation state
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView(userId: userId, repoService: dataFetchRepo)
                .environmentObject(self)
        case .profile:
            ProfileView()
                .environmentObject(self)
        case .addExpense:
            AddExpenseView(repoService: expenseRepo)
                .environmentObject(self)
        case .addIncome:
            AddIncomeView(repoService: incomeRepo)
                .environmentObject(self)
        case .createBudget(let month, let year):
            CreateBudgetView(month: month, year: year)
                .environmentObject(self)
        case .editBudget(let budgetCategories, let month, let year):
            EditBudgetView(budgetCategories: budgetCategories, month: month, year: year)
                .environmentObject(self)
        case .expenseDetails(let expense):
            ExpenseDetailsView(expense: expense, repoService: expenseRepo)
                .environmentObject(self)
        case .incomeDetails(let income):
            IncomeDetailsView(income: income, repoSerice: incomeRepo)
                .environmentObject(self)
        case .allExpenses(let budgetCategories, let totalBudget, let expenses, let month, let year):
            AllExpensesView(budgetCategories: budgetCategories, totalBudget: totalBudget, expenses: expenses, month: month, year: year)
                .environmentObject(self)
        case .allIncomes(let incomes, let month, let year):
            AllIncomesView(incomes: incomes, month: month, year: year)
                .environmentObject(self)
        case .allMajorExpenses:
            AllMajorExpensesView(repoService: dataFetchRepo)
                .environmentObject(self)
        case .addMajorExpense:
            AddMajorExpenseView(repoService: majorExpenseRepo)
                .environmentObject(self)
        case .majorExpenseDetails(let majorExpense):
            MajorExpenseDetailsView(majorExpense: majorExpense, repoService: majorExpenseRepo)
                .environmentObject(self)
        case .categoryDetail(let category, let expenses, let month, let year):
            CategoryDetailView(category: category, expenses: expenses, month: month, year: year)
                .environmentObject(self)
        case .savingsAnalysis(let expenses, let incomes, let totalBudget, let month, let year):
            SavingsAnalysisScreen(expenses: expenses, incomes: incomes, totalBudget: totalBudget, month: month, year: year)
                .environmentObject(self)
        case .about:
            AboutView()
                .environmentObject(self)
        case .financialGoals:
            FinancialGoalListView(repoService: financialGoalRepo)
                .environmentObject(self)
        case .addFinancialGoal:
            AddFinancialGoalView(repoService: financialGoalRepo)
                .environmentObject(self)
        case .financialGoalDetails(let goal):
            FinancialGoalDetailsView(goal: goal, repoService: financialGoalRepo)
                .environmentObject(self)
        case .editFinancialGoal(let goal):
            AddFinancialGoalView(repoService: financialGoalRepo, goalToEdit: goal)
                .environmentObject(self)
        case .addContribution(let goalId, let goalTitle):
            AddGoalContributionView(repoService: financialGoalRepo, goalId: goalId, goalTitle: goalTitle)
                .environmentObject(self)
        case .editContribution(let goalId, let goalTitle, let contribution):
            AddGoalContributionView(repoService: financialGoalRepo, goalId: goalId, goalTitle: goalTitle, contributionToEdit: contribution)
                .environmentObject(self)
        case .monthlyTrends:
            MonthlyTrendsView(userId: userId, repoService: dataFetchRepo)
                .environmentObject(self)
        case .settings:
            SettingsView()
                .environmentObject(self)
        }
    }
    
    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .profile:
            ProfileView()
                .environmentObject(self)
        }
    }
}
