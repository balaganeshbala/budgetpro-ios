import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    // Budget data
    @Published var budgetCategories: [BudgetCategory] = []
    @Published var totalBudget: Double = 0
    @Published var totalSpent: Double = 0
    
    // Expenses data
    @Published var recentExpenses: [Expense] = []
    
    // Incomes data
    @Published var recentIncomes: [Income] = []
    
    let userId: String
    private let repoService: DataFetchRepoService
    
    private var currentLoadingTask: Task<Void, Never>?

    init(
        userId: String,
        repoService: DataFetchRepoService
    ) {
        self.userId = userId
        self.repoService = repoService
    }
    
    func loadData(month: Int, year: Int) async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performLoadData(month: month, year: year)
        }
        await currentLoadingTask?.value
    }
    
    private func performLoadData(month: Int, year: Int) async {
        guard !Task.isCancelled else { return }
        isLoading = true
        errorMessage = ""
        
        async let expensesData = loadExpensesData(month: month, year: year)
        async let incomesData = loadIncomesData(month: month, year: year)
        
        do {
            let (expenses, incomes) = try await (expensesData, incomesData)
            guard !Task.isCancelled else { return }
            let budget = try await loadBudgetData(month: month, year: year, expenses: expenses)
            guard !Task.isCancelled else { return }
            
            self.budgetCategories = budget.categories
            self.totalBudget = budget.total
            self.totalSpent = budget.spent
            self.recentExpenses = expenses
            self.recentIncomes = incomes
        } catch {
            guard !Task.isCancelled else { return }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Request cancelled - this is normal")
                return
            }
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func refreshData(month: Int, year: Int) async {
        await loadData(month: month, year: year)
    }
    
    // MARK: - Private Methods
    
    private func loadBudgetData(month: Int, year: Int, expenses: [Expense]) async throws -> (categories: [BudgetCategory], total: Double, spent: Double) {
        do {
            let targetDate = CommonHelpers.getMonthStartDate(month: month, year: year)
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .eq, value: targetDate)
            ]
            let budgetEntries: [BudgetEntry] = try await repoService.fetchAll(from: "budget", filters: filters)
            
            var categories: [BudgetCategory] = []
            var totalBudget: Double = 0
            
            let expensesByCategory = Dictionary(grouping: expenses) { $0.category.displayName }
            let budgetsByCategory = Dictionary(uniqueKeysWithValues: budgetEntries.map {
                (ExpenseCategory.from(categoryName: $0.category).displayName, $0.amount)
            })
            let budgetIdsByCategory = Dictionary(uniqueKeysWithValues: budgetEntries.map {
                (ExpenseCategory.from(categoryName: $0.category).displayName, $0.id.map(String.init) ?? UUID().uuidString)
            })
            let allCategoryNames = Set(expensesByCategory.keys).union(Set(budgetsByCategory.keys))
            
            for categoryName in allCategoryNames {
                let budgetAmount = budgetsByCategory[categoryName] ?? 0
                let spent = expensesByCategory[categoryName]?.reduce(0) { $0 + $1.amount } ?? 0
                let budgetId = budgetIdsByCategory[categoryName] ?? UUID().uuidString
                let category = BudgetCategory(
                    id: budgetId,
                    name: categoryName,
                    budget: budgetAmount,
                    spent: spent
                )
                categories.append(category)
                totalBudget += budgetAmount
            }
            
            categories.sort { c1, c2 in
                let s1 = getCategoryStatus(c1)
                let s2 = getCategoryStatus(c2)
                let p1 = getCategoryPriority(s1)
                let p2 = getCategoryPriority(s2)
                if p1 != p2 { return p1 > p2 }
                return c1.name < c2.name
            }
            let totalSpent = expenses.reduce(0) { $0 + $1.amount }
            return (categories: categories, total: totalBudget, spent: totalSpent)
        } catch {
            throw HomeError.decodingError
        }
    }
    
    private func loadExpensesData(month: Int, year: Int) async throws -> [Expense] {
        do {
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .gte, value: CommonHelpers.getMonthStartDate(month: month, year: year)),
                RepoQueryFilter(column: "date", op: .lt, value: CommonHelpers.getMonthEndDate(month: month, year: year))
            ]
            let response: [Expense] = try await repoService.fetchAll(from: "expenses", filters: filters)
            return response.map { expense in
                // Ensure date is set correctly if using custom decoding
                return expense
            }
        } catch {
            throw HomeError.decodingError
        }
    }
    
    private func loadIncomesData(month: Int, year: Int) async throws -> [Income] {
        do {
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .gte, value: CommonHelpers.getMonthStartDate(month: month, year: year)),
                RepoQueryFilter(column: "date", op: .lt, value: CommonHelpers.getMonthEndDate(month: month, year: year))
            ]
            let response: [Income] = try await repoService.fetchAll(from: "incomes", filters: filters)
            return response
        } catch {
            throw HomeError.decodingError
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCategoryStatus(_ category: BudgetCategory) -> String {
        if category.budget == 0 && category.spent > 0 {
            return "Unplanned"
        } else if category.budget == 0 {
            return "No Budget"
        } else if category.spent > category.budget {
            return "Overspent"
        } else {
            return "On Track"
        }
    }
    
    private func getCategoryPriority(_ status: String) -> Int {
        switch status {
        case "Overspent": return 3
        case "Unplanned": return 2
        default: return 1
        }
    }
}

enum HomeError: LocalizedError {
    case userNotFound
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .networkError:
            return "Network error. Please check your connection."
        case .decodingError:
            return "Error processing data. Please try again."
        }
    }
}
