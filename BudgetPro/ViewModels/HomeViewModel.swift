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
    
    func loadData(month: Int, year: Int) async {
        isLoading = true
        errorMessage = ""
        
        async let budgetData = loadBudgetData(month: month, year: year)
        async let expensesData = loadExpensesData(month: month, year: year)
        async let incomesData = loadIncomesData(month: month, year: year)
        
        do {
            let (budget, expenses, incomes) = try await (budgetData, expensesData, incomesData)
            
            self.budgetCategories = budget.categories
            self.totalBudget = budget.total
            self.totalSpent = budget.spent
            self.recentExpenses = expenses
            self.recentIncomes = incomes
            
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData(month: Int, year: Int) async {
        await loadData(month: month, year: year)
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
            
            // Group expenses by category
            let expensesByCategory = Dictionary(grouping: expensesResponse) { $0.category }
            
            for budget in budgetResponse {
                let spent = expensesByCategory[budget.category]?.reduce(0) { $0 + $1.amount } ?? 0
                
                let category = BudgetCategory(
                    id: UUID().uuidString,  // Generate ID since it's not stored in budget table
                    name: budget.category,
                    budget: budget.amount,
                    spent: spent
                )
                
                categories.append(category)
                totalBudget += budget.amount
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
            Expense(
                id: expenseResponse.id,
                name: expenseResponse.name,
                amount: expenseResponse.amount,
                category: expenseResponse.category,
                date: ISO8601DateFormatter().date(from: expenseResponse.date) ?? Date(),
                categoryIcon: getCategoryIcon(for: expenseResponse.category),
                categoryColor: getCategoryColor(for: expenseResponse.category)
            )
        }
    }
    
    private func loadIncomesData(month: Int, year: Int) async throws -> [Income] {
        guard let userId = supabaseManager.currentUser?.id else {
            throw HomeError.userNotFound
        }
        
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
                date: ISO8601DateFormatter().date(from: incomeResponse.date) ?? Date(),
                categoryIcon: getIncomeCategoryIcon(for: incomeResponse.category)
            )
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
    
    private func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "entertainment": return "tv"
        case "shopping": return "bag.fill"
        case "health": return "heart.fill"
        case "utilities": return "bolt.fill"
        case "education": return "book.fill"
        case "travel": return "airplane"
        case "personal care": return "scissors"
        case "groceries": return "cart.fill"
        case "rent": return "house.fill"
        case "insurance": return "shield.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "miscellaneous": return "ellipsis.circle"
        default: return "dollarsign.circle"
        }
    }
    
    private func getCategoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "entertainment": return .purple
        case "shopping": return .pink
        case "health": return .red
        case "utilities": return .yellow
        case "education": return .green
        case "travel": return .cyan
        case "personal care": return .indigo
        case "groceries": return .brown
        case "rent": return .gray
        case "insurance": return .mint
        case "investment": return .teal
        case "miscellaneous": return .secondary
        default: return Color(red: 0.2, green: 0.6, blue: 0.5)
        }
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
}

// MARK: - Data Models

struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let budget: Double
    let spent: Double
}

struct Expense: Identifiable {
    let id: Int
    let name: String
    let amount: Double
    let category: String
    let date: Date
    let categoryIcon: String
    let categoryColor: Color
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

struct Income: Identifiable {
    let id: Int
    let source: String
    let amount: Double
    let category: String
    let date: Date
    let categoryIcon: String
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

// MARK: - API Response Models

struct BudgetResponse: Codable {
    let id: Int
    let category: String    // Removed id, month, year - only keeping essential fields
    let amount: Double
    let date: String       // Added date field to match Flutter structure
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case amount
        case date
        case userId = "user_id"
    }
}

struct ExpenseResponse: Codable {
    let id: Int
    let date: String
    let name: String
    let category: String
    let amount: Double
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case name
        case category
        case amount
        case userId = "user_id"
    }
}

struct IncomeResponse: Codable {
    let id: Int
    let source: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case source
        case amount
        case category
        case date
        case userId = "user_id"
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
