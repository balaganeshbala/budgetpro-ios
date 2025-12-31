import Foundation
import Supabase

@MainActor
class CreateBudgetViewModel: ObservableObject {
    @Published var categoryBudgets: [String: Double] = [:]
    @Published var totalBudget: Double = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    
    private let supabaseManager = SupabaseManager.shared
    private let month: Int
    private let year: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
        
        // Initialize all categories with 0
        for category in ExpenseCategory.userSelectableCategories {
            categoryBudgets[category.displayName] = 0
        }
    }
    
    var canSave: Bool {
        // Allow saving even if total budget is 0, as user might want to set all categories to 0
        return !isLoading
    }
    
    var categoriesWithBudget: Int {
        return categoryBudgets.values.filter { $0 > 0 }.count
    }
    
    var totalCategories: Int {
        return ExpenseCategory.userSelectableCategories.count
    }
    
    func updateCategoryBudget(_ category: String, amount: Double) {
        categoryBudgets[category] = amount
        calculateTotalBudget()
    }
    
    func loadExistingBudget() {
        Task {
            await fetchExistingBudget()
        }
    }
    
    func saveBudget() async {
        guard canSave else {
            errorMessage = "Unable to save budget at this time"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw CreateBudgetError.userNotFound
            }
            
            let targetDate = getMonthStartDate()
            
            // First, check if any budget exists for this month/year
            let existingBudgets: [BudgetEntry] = try await supabaseManager.client
                .from("budget")
                .select("*")
                .eq("user_id", value: userId)
                .eq("date", value: targetDate)
                .execute()
                .value
            
            if !existingBudgets.isEmpty {
                // If budget exists, delete all entries for this month and recreate
                // This is acceptable for create budget since user is starting fresh
                try await supabaseManager.client
                    .from("budget")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("date", value: targetDate)
                    .execute()
            }
            
            // Create new budget entries
            let budgetEntries = createBudgetEntries(userId: userId.uuidString)
            
            if !budgetEntries.isEmpty {
                // Insert new budget entries
                try await supabaseManager.client
                    .from("budget")
                    .insert(budgetEntries)
                    .execute()
            }
            
            isSuccess = true
            
        } catch {
            print("Save budget error: \(error)")
            errorMessage = "Failed to save budget: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func calculateTotalBudget() {
        totalBudget = categoryBudgets.values.reduce(0, +)
    }
    
    private func fetchExistingBudget() async {
        guard let userId = supabaseManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let targetDate = getMonthStartDate()
            
            let existingBudgets: [BudgetEntry] = try await supabaseManager.client
                .from("budget")  // Changed from "budgets" to "budget"
                .select("*")
                .eq("user_id", value: userId)
                .eq("date", value: targetDate)  // Changed to use date instead of month/year
                .execute()
                .value
            
            // Update category budgets with existing data
            for budget in existingBudgets {
                categoryBudgets[budget.category] = budget.amount
            }
            
            calculateTotalBudget()
            
        } catch {
            errorMessage = "Failed to load existing budget: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func deleteExistingBudgets(userId: String) async throws {
        let targetDate = getMonthStartDate()
        
        try await supabaseManager.client
            .from("budget")  // Changed from "budgets" to "budget"
            .delete()
            .eq("user_id", value: userId)
            .eq("date", value: targetDate)  // Changed to use date instead of month/year
            .execute()
    }
    
    private func createBudgetEntries(userId: String) -> [BudgetEntry] {
        let targetDate = getMonthStartDate()
        
        return categoryBudgets.compactMap { (categoryDisplayName, amount) in
            // Include all categories, even those with 0 amounts
            // Find the corresponding ExpenseCategory and use its rawValue
            let expenseCategory = ExpenseCategory.userSelectableCategories.first { $0.displayName == categoryDisplayName } ?? .food
            
            return BudgetEntry(
                date: targetDate,  // Changed to use date instead of separate month/year
                category: expenseCategory.rawValue,
                amount: amount,
                userId: userId
            )
        }
    }
    
    private func getMonthStartDate() -> String {
        // Format: "2025-07-01" to match Flutter implementation
        let components = DateComponents(year: year, month: month, day: 1)
        let date = Calendar.current.date(from: components) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}


// MARK: - Errors

enum CreateBudgetError: LocalizedError {
    case userNotFound
    case noBudgetSet
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .noBudgetSet:
            return "Please set at least one budget category."
        case .saveFailed:
            return "Failed to save budget. Please try again."
        }
    }
}
