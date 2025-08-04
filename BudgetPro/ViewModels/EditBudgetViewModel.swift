import Foundation

extension Notification.Name {
    static let budgetDataChanged = Notification.Name("budgetDataChanged")
}

@MainActor
class EditBudgetViewModel: ObservableObject {
    @Published var editableBudgets: [EditableBudgetCategory] = []
    @Published var totalBudget: Double = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    
    // Store original budgets for comparison
    let originalBudgets: [String: Double]
    let originalBudgetIds: [String: String] // categoryDisplayName -> budgetId
    
    private let supabaseManager = SupabaseManager.shared
    private let month: Int
    private let year: Int
    
    init(budgetCategories: [BudgetCategory], month: Int, year: Int) {
        self.month = month
        self.year = year
        
        // Store original budgets and IDs
        var originalBudgetMap: [String: Double] = [:]
        var originalIdMap: [String: String] = [:]
        
        // Convert BudgetCategory to EditableBudgetCategory
        var editableList: [EditableBudgetCategory] = []
        
        // First, add existing budget categories
        
        for budgetCategory in budgetCategories {
            // Match by display name since that's what's stored in the normalized budget data
            if let expenseCategory = ExpenseCategory.userSelectableCategories.first(where: { $0.displayName == budgetCategory.name }) {
                
                let editableBudget = EditableBudgetCategory(
                    category: expenseCategory,
                    amount: budgetCategory.budget
                )
                editableList.append(editableBudget)
                
                // Use the ExpenseCategory's displayName as the key for consistency
                originalBudgetMap[expenseCategory.displayName] = budgetCategory.budget
                // budgetCategory.id now contains the actual database ID from BudgetResponse
                originalIdMap[expenseCategory.displayName] = budgetCategory.id
            }
        }
        
        // Then, add remaining categories that don't have budgets yet
        // Create a set of existing display names from the database
        let existingDisplayNames = Set(budgetCategories.map { $0.name })
        
        for expenseCategory in ExpenseCategory.userSelectableCategories {
            // Check if this category's display name is not in the existing budgets
            if !existingDisplayNames.contains(expenseCategory.displayName) {
                let editableBudget = EditableBudgetCategory(
                    category: expenseCategory,
                    amount: 0
                )
                editableList.append(editableBudget)
                originalBudgetMap[expenseCategory.displayName] = 0
            }
        }
        
        // Sort by budget amount (highest first), then alphabetically for categories with same amount
        editableList.sort { budget1, budget2 in
            if budget1.amount != budget2.amount {
                return budget1.amount > budget2.amount  // Higher amounts first
            } else {
                return budget1.category.displayName < budget2.category.displayName  // Alphabetical for same amounts
            }
        }
        
        self.editableBudgets = editableList
        self.originalBudgets = originalBudgetMap
        self.originalBudgetIds = originalIdMap
        
        calculateTotalBudget()
    }
    
    var canUpdate: Bool {
        return totalBudget > 0 && !isLoading && hasChanges
    }
    
    var hasChanges: Bool {
        for editableBudget in editableBudgets {
            let original = originalBudgets[editableBudget.category.displayName] ?? 0
            if editableBudget.amount != original {
                return true
            }
        }
        return false
    }
    
    var categoriesWithBudget: Int {
        return editableBudgets.filter { $0.amount > 0 }.count
    }
    
    var totalCategories: Int {
        return ExpenseCategory.userSelectableCategories.count
    }
    
    func updateCategoryBudget(_ category: String, amount: Double) {
        if let index = editableBudgets.firstIndex(where: { $0.category.displayName == category }) {
            editableBudgets[index].amount = amount
            calculateTotalBudget()
        }
    }
    
    func updateBudget() async {
        guard canUpdate else {
            errorMessage = "No changes to update or invalid budget"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id.uuidString else {
                throw EditBudgetError.userNotFound
            }
            
            let targetDate = getMonthStartDate()
            
            // Process each category individually
            for editableBudget in editableBudgets {
                let categoryDisplayName = editableBudget.category.displayName
                let categoryRawValue = editableBudget.category.rawValue
                let newAmount = editableBudget.amount
                let originalAmount = originalBudgets[categoryDisplayName] ?? 0
                
                print("Processing category: \(categoryDisplayName), original: \(originalAmount), new: \(newAmount)")
                
                // Skip if no change
                if newAmount == originalAmount {
                    print("Skipping \(categoryDisplayName) - no change")
                    continue
                }
                
                if newAmount > 0 {
                    if let budgetId = originalBudgetIds[categoryDisplayName], 
                       Int(budgetId) != nil { // Only update if we have a valid database ID
                        // Update existing budget using ID
                        try await updateBudgetById(
                            budgetId: budgetId,
                            amount: newAmount
                        )
                    } else {
                        // Insert new budget entry
                        try await insertNewBudget(
                            userId: userId,
                            date: targetDate,
                            category: categoryRawValue,
                            amount: newAmount
                        )
                    }
                } else {
                    // Delete entry if amount is 0 and it existed before
                    if originalAmount > 0, 
                       let budgetId = originalBudgetIds[categoryDisplayName],
                       Int(budgetId) != nil { // Only delete if we have a valid database ID
                        try await deleteBudgetById(budgetId: budgetId)
                    }
                }
            }
            
            isSuccess = true
            
            // Post notification to refresh data
            NotificationCenter.default.post(name: .budgetDataChanged, object: nil)
            
        } catch {
            print("Update budget error: \(error)")
            errorMessage = "Failed to update budget: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Database Operations
    
    private func updateBudgetById(budgetId: String, amount: Double) async throws {
        // Convert string ID back to integer for database query
        guard let intId = Int(budgetId) else {
            throw EditBudgetError.updateFailed
        }
        
        try await supabaseManager.client
            .from("budget")
            .update([
                "amount": amount
            ])
            .eq("id", value: intId)
            .execute()
        
        print("Budget updated: id=\(intId), amount=\(amount)")
    }
    
    private func insertNewBudget(userId: String, date: String, category: String, amount: Double) async throws {
        let budgetEntry = BudgetEntry(
            date: date,
            category: category,
            amount: amount,
            userId: userId
        )
        
        try await supabaseManager.client
            .from("budget")
            .insert(budgetEntry)
            .execute()
        
        print("Budget inserted: userId=\(userId), date=\(date), category=\(category), amount=\(amount)")
    }
    
    private func deleteBudgetById(budgetId: String) async throws {
        // Convert string ID back to integer for database query
        guard let intId = Int(budgetId) else {
            throw EditBudgetError.updateFailed
        }
        
        try await supabaseManager.client
            .from("budget")
            .delete()
            .eq("id", value: intId)
            .execute()
        
        print("Budget deleted: id=\(intId)")
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func calculateTotalBudget() {
        totalBudget = editableBudgets.reduce(0) { $0 + $1.amount }
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

enum EditBudgetError: LocalizedError {
    case userNotFound
    case noChanges
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .noChanges:
            return "No changes made to the budget."
        case .updateFailed:
            return "Failed to update budget. Please try again."
        }
    }
}
