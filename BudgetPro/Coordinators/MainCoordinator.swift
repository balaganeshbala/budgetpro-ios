import SwiftUI

@MainActor
class MainCoordinator: Coordinator {
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Tab = .home
    @Published var presentedSheet: Sheet?
    
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
        case allExpenses(expenses: [Expense], month: Int, year: Int)
        case allIncomes(incomes: [Income], month: Int, year: Int)
        case budgetCategories(budgetCategories: [BudgetCategory], totalBudget: Double, totalSpent: Double, expenses: [Expense], month: Int, year: Int)
        case categoryDetail(category: BudgetCategory, expenses: [Expense], month: Int, year: Int)
        case savingsAnalysis(expenses: [Expense], incomes: [Income], totalBudget: Double, month: String, year: String)
        case about
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
            navigationPath.removeLast(navigationPath.count)
        case .profile:
            presentedSheet = .profile
        case .addExpense:
            navigationPath.append(route)
        case .addIncome:
            navigationPath.append(route)
        default:
            navigationPath.append(route)
        }
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
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
        navigationPath.removeLast(navigationPath.count)
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
                .environmentObject(self)
        case .profile:
            ProfileView()
                .environmentObject(self)
        case .addExpense:
            AddExpenseView()
                .environmentObject(self)
        case .addIncome:
            AddIncomeView()
                .environmentObject(self)
        case .createBudget(let month, let year):
            CreateBudgetView(month: month, year: year)
                .environmentObject(self)
        case .editBudget(let budgetCategories, let month, let year):
            EditBudgetView(budgetCategories: budgetCategories, month: month, year: year)
                .environmentObject(self)
        case .expenseDetails(let expense):
            ExpenseDetailsView(expense: expense)
                .environmentObject(self)
        case .incomeDetails(let income):
            IncomeDetailsView(income: income)
                .environmentObject(self)
        case .allExpenses(let expenses, let month, let year):
            AllExpensesView(expenses: expenses, month: month, year: year)
                .environmentObject(self)
        case .allIncomes(let incomes, let month, let year):
            AllIncomesView(incomes: incomes, month: month, year: year)
                .environmentObject(self)
        case .budgetCategories(let budgetCategories, let totalBudget, let totalSpent, let expenses, let month, let year):
            BudgetCategoriesView(budgetCategories: budgetCategories, totalBudget: totalBudget, totalSpent: totalSpent, expenses: expenses, month: month, year: year)
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
