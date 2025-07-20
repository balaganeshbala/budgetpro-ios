//
//  ExpenseDetailsViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 15/07/25.
//


import Foundation

@MainActor
class ExpenseDetailsViewModel: ObservableObject {
    @Published var expenseName: String = ""
    @Published var amountText: String = ""
    @Published var selectedCategory: ExpenseCategory = .food
    @Published var selectedDate: Date = Date()
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    // Original values for comparison
    private let originalExpense: Expense
    private var originalName: String
    private var originalAmount: Double
    private var originalCategory: ExpenseCategory
    private var originalDate: Date
    
    private let supabaseManager = SupabaseManager.shared
    
    init(expense: Expense) {
        self.originalExpense = expense
        self.originalName = expense.name
        self.originalAmount = expense.amount
        self.originalDate = expense.date
        
        // Find the matching category using the from method
        self.originalCategory = ExpenseCategory.from(categoryName: expense.category)
    }
    
    var hasChanges: Bool {
        let currentAmount = Double(amountText) ?? 0
        return expenseName != originalName ||
               currentAmount != originalAmount ||
               selectedCategory != originalCategory ||
               !Calendar.current.isDate(selectedDate, inSameDayAs: originalDate)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    func loadExpenseData() {
        expenseName = originalName
        amountText = originalAmount > 0 ? String(format: "%.2f", originalAmount) : ""
        selectedCategory = originalCategory
        selectedDate = originalDate
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0 &&
                      hasChanges
    }
    
    func updateExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw ExpenseDetailsError.userNotFound
            }
            
            let amount = Double(amountText) ?? 0
            let dateString = formatDateForDatabase(selectedDate)
            
            // Update the expense in database
            try await supabaseManager.client
                .from("expenses")
                .update([
                    "name": expenseName.trimmingCharacters(in: .whitespacesAndNewlines),
                    "amount": amount.rawValue,
                    "category": selectedCategory.displayName,
                    "date": dateString
                ])
                .eq("id", value: originalExpense.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Expense updated successfully!"
            isSuccess = true
            
            // Notify that expense data has changed
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
            
        } catch {
            print("Update expense error: \(error)")
            errorMessage = "Failed to update expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteExpense() async {
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw ExpenseDetailsError.userNotFound
            }
            
            // Delete the expense from database
            try await supabaseManager.client
                .from("expenses")
                .delete()
                .eq("id", value: originalExpense.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Expense deleted successfully!"
            isSuccess = true
            
            // Notify that expense data has changed
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
            
        } catch {
            print("Delete expense error: \(error)")
            errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func formatDateForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Errors

enum ExpenseDetailsError: LocalizedError {
    case userNotFound
    case invalidData
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .invalidData:
            return "Invalid expense data. Please check your inputs."
        case .updateFailed:
            return "Failed to update expense. Please try again."
        case .deleteFailed:
            return "Failed to delete expense. Please try again."
        }
    }
}
