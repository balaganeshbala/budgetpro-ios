import Foundation
import Supabase
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
    
    private let supabaseManager = SupabaseManager.shared
    
    // Add this to prevent concurrent executions
    private var currentLoadingTask: Task<Void, Never>?
    
    func loadData(month: Int, year: Int) async {
        // Cancel any existing task
        currentLoadingTask?.cancel()
        
        // Create new task
        currentLoadingTask = Task {
            await performLoadData(month: month, year: year)
        }
        
        // Wait for completion
        await currentLoadingTask?.value
    }
    
    private func performLoadData(month: Int, year: Int) async {
        // Check if cancelled before starting
        guard !Task.isCancelled else { return }
        
        isLoading = true
        errorMessage = ""
        
        async let budgetData = loadBudgetData(month: month, year: year)
        async let expensesData = loadExpensesData(month: month, year: year)
        async let incomesData = loadIncomesData(month: month, year: year)
        
        do {
            let (budget, expenses, incomes) = try await (budgetData, expensesData, incomesData)
            
            // Check if cancelled before updating UI
            guard !Task.isCancelled else { return }
            
            self.budgetCategories = budget.categories
            self.totalBudget = budget.total
            self.totalSpent = budget.spent
            self.recentExpenses = expenses
            self.recentIncomes = incomes
            
        } catch {
            // Check if cancelled
            guard !Task.isCancelled else { return }
            
            // Handle cancellation errors
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
    
    func loadAllExpenses(month: Int, year: Int) async throws -> [Expense] {
        guard let userId = supabaseManager.currentUser?.id else {
            throw HomeError.userNotFound
        }
        
        let response: [ExpenseResponse] = try await supabaseManager.client
            .from("expenses")
            .select("*")
            .eq("user_id", value: userId)
            .gte("date", value: getMonthStartDate(month: month, year: year))
            .lt("date", value: getMonthEndDate(month: month, year: year))
            .order("date", ascending: false)
            .execute()
            .value
        
        return response.map { expenseResponse in
            let categoryEnum = ExpenseCategory.from(categoryName: expenseResponse.category)
            return Expense(
                id: expenseResponse.id,
                name: expenseResponse.name,
                amount: expenseResponse.amount,
                category: expenseResponse.category,
                date: parseDate(expenseResponse.date),
                categoryIcon: categoryEnum.iconName,
                categoryColor: categoryEnum.color
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func loadBudgetData(month: Int, year: Int) async throws -> (categories: [BudgetCategory], total: Double, spent: Double) {
        guard let userId = supabaseManager.currentUser?.id else {
            throw HomeError.userNotFound
        }
        
        do {
            // Create target date for budget lookup (matches Flutter format)
            let targetDate = getMonthStartDate(month: month, year: year)
            
            // Load budget categories for the month/year
            let budgetResponse: [BudgetResponse] = try await supabaseManager.client
                .from("budget")  // Changed from "budgets" to "budget"
                .select("*")
                .eq("user_id", value: userId)
                .eq("date", value: targetDate)  // Changed to use date instead of month/year
                .execute()
                .value
            
            var categories: [BudgetCategory] = []
            var totalBudget: Double = 0
            
            // Load expenses for calculating spent amounts
            let expensesResponse: [ExpenseResponse] = try await supabaseManager.client
                .from("expenses")
                .select("*")
                .eq("user_id", value: userId)
                .gte("date", value: getMonthStartDate(month: month, year: year))
                .lt("date", value: getMonthEndDate(month: month, year: year))
                .execute()
                .value
            
            // Group expenses by category, normalized by ExpenseCategory
            let expensesByCategory = Dictionary(grouping: expensesResponse) { expense in
                ExpenseCategory.from(categoryName: expense.category).displayName
            }
            
            // Create a dictionary of budget amounts by category
            let budgetsByCategory = Dictionary(uniqueKeysWithValues: budgetResponse.map { budget in
                (ExpenseCategory.from(categoryName: budget.category).displayName, budget.amount)
            })
            
            // Get all categories that have either budget or expenses
            let allCategoryNames = Set(expensesByCategory.keys).union(Set(budgetsByCategory.keys))
            
            for categoryName in allCategoryNames {
                let budgetAmount = budgetsByCategory[categoryName] ?? 0
                let spent = expensesByCategory[categoryName]?.reduce(0) { $0 + $1.amount } ?? 0
                
                let category = BudgetCategory(
                    id: UUID().uuidString,
                    name: categoryName,
                    budget: budgetAmount,
                    spent: spent
                )
                
                categories.append(category)
                totalBudget += budgetAmount
            }
            
            // Sort categories: Unplanned and Overspent first, then by name
            categories.sort { category1, category2 in
                let status1 = getCategoryStatus(category1)
                let status2 = getCategoryStatus(category2)
                
                // Priority order: Overspent (3), Unplanned (2), others (1)
                let priority1 = getCategoryPriority(status1)
                let priority2 = getCategoryPriority(status2)
                
                if priority1 != priority2 {
                    return priority1 > priority2
                } else {
                    // Within same priority, sort by name
                    return category1.name < category2.name
                }
            }
            
            let totalSpent = expensesResponse.reduce(0) { $0 + $1.amount }
            
            return (categories: categories, total: totalBudget, spent: totalSpent)
        } catch {
            throw HomeError.decodingError
        }
    }
    
    private func loadExpensesData(month: Int, year: Int) async throws -> [Expense] {
        guard let userId = supabaseManager.currentUser?.id else {
            throw HomeError.userNotFound
        }
        
        do {
            let response: [ExpenseResponse] = try await supabaseManager.client
                .from("expenses")
                .select("*")
                .eq("user_id", value: userId)
                .gte("date", value: getMonthStartDate(month: month, year: year))
                .lt("date", value: getMonthEndDate(month: month, year: year))
                .order("date", ascending: false)
                .limit(10)
                .execute()
                .value
            
            return response.map { expenseResponse in
                let categoryEnum = ExpenseCategory.from(categoryName: expenseResponse.category)
                return Expense(
                    id: expenseResponse.id,
                    name: expenseResponse.name,
                    amount: expenseResponse.amount,
                    category: expenseResponse.category,
                    date: parseDate(expenseResponse.date),
                    categoryIcon: categoryEnum.iconName,
                    categoryColor: categoryEnum.color
                )
            }
        } catch {
            throw HomeError.decodingError
        }
    }
    
    private func loadIncomesData(month: Int, year: Int) async throws -> [Income] {
        guard let userId = supabaseManager.currentUser?.id else {
            throw HomeError.userNotFound
        }
        
        do {
            let response: [IncomeResponse] = try await supabaseManager.client
                .from("incomes")
                .select("*")
                .eq("user_id", value: userId)
                .gte("date", value: getMonthStartDate(month: month, year: year))
                .lt("date", value: getMonthEndDate(month: month, year: year))
                .order("date", ascending: false)
                .limit(10)
                .execute()
                .value
            
            return response.map { incomeResponse in
                Income(
                    id: incomeResponse.id,
                    source: incomeResponse.source,
                    amount: incomeResponse.amount,
                    category: incomeResponse.category,
                    date: parseDate(incomeResponse.date),
                    categoryIcon: getIncomeCategoryIcon(for: incomeResponse.category)
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
        formatter.dateFormat = "yyyy-MM-dd"  // Changed to match Flutter format
        return formatter.string(from: startDate)
    }
    
    private func getMonthEndDate(month: Int, year: Int) -> String {
        let startDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // Changed to match Flutter format
        return formatter.string(from: endDate)
    }
    
    
    private func getIncomeCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "salary": return "briefcase.fill"
        case "freelance": return "laptopcomputer"
        case "business": return "building.2.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "rental": return "house.fill"
        case "bonus": return "gift.fill"
        case "other": return "plus.circle"
        default: return "dollarsign.circle"
        }
    }
    
    // Add this method to your HomeViewModel class
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Fallback: try ISO8601 format for older data
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // Final fallback
        return Date()
    }
    
    // Helper methods for category sorting
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


// MARK: - Errors

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
