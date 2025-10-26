import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Budget data
    @Published var budgetCategories: [BudgetCategory] = []
    @Published var totalBudget: Double = 0
    @Published var totalSpent: Double = 0
    
    // Expenses data
    @Published var recentExpenses: [Expense] = []
    
    // Incomes data
    @Published var recentIncomes: [Income] = []
    
    private let userId: String
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
            let targetDate = getMonthStartDate(month: month, year: year)
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .eq, value: targetDate)
            ]
            let budgetResponse: [BudgetResponse] = try await repoService.fetchAll(from: "budget", filters: filters)
            
            var categories: [BudgetCategory] = []
            var totalBudget: Double = 0
            
            let expensesByCategory = Dictionary(grouping: expenses) { $0.category.displayName }
            let budgetsByCategory = Dictionary(uniqueKeysWithValues: budgetResponse.map {
                (ExpenseCategory.from(categoryName: $0.category).displayName, $0.amount)
            })
            let budgetIdsByCategory = Dictionary(uniqueKeysWithValues: budgetResponse.map {
                (ExpenseCategory.from(categoryName: $0.category).displayName, String($0.id))
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
                RepoQueryFilter(column: "date", op: .gte, value: getMonthStartDate(month: month, year: year)),
                RepoQueryFilter(column: "date", op: .lt, value: getMonthEndDate(month: month, year: year))
            ]
            let response: [ExpenseResponse] = try await repoService.fetchAll(from: "expenses", filters: filters)
            return response.map { expenseResponse in
                let categoryEnum = ExpenseCategory.from(categoryName: expenseResponse.category)
                return Expense(
                    id: expenseResponse.id,
                    name: expenseResponse.name,
                    amount: expenseResponse.amount,
                    category: categoryEnum,
                    date: parseDate(expenseResponse.date)
                )
            }
        } catch {
            throw HomeError.decodingError
        }
    }
    
    private func loadIncomesData(month: Int, year: Int) async throws -> [Income] {
        do {
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .gte, value: getMonthStartDate(month: month, year: year)),
                RepoQueryFilter(column: "date", op: .lt, value: getMonthEndDate(month: month, year: year))
            ]
            let response: [IncomeResponse] = try await repoService.fetchAll(from: "incomes", filters: filters)
            return response.map { incomeResponse in
                let categoryEnum = IncomeCategory.from(categoryName: incomeResponse.category)
                return Income(
                    id: incomeResponse.id,
                    source: incomeResponse.source,
                    amount: incomeResponse.amount,
                    category: categoryEnum,
                    date: parseDate(incomeResponse.date)
                )
            }
        } catch {
            throw HomeError.decodingError
        }
    }
    
    // MARK: - Helper Functions
    
    private func getMonthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
    
    private func getMonthStartDate(month: Int, year: Int) -> String {
        let startDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startDate)
    }
    
    private func getMonthEndDate(month: Int, year: Int) -> String {
        let startDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: endDate)
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            return date
        }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        return Date()
    }
    
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
