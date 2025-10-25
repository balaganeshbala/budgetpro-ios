//
//  AddExpenseViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 17/07/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let expenseDataChanged = Notification.Name("expenseDataChanged")
}

// MARK: - Add Expense View Model
@MainActor
class AddExpenseViewModel: ObservableObject, TransactionFormStateProtocol, AddTransactionActions {
    @Published var expenseName: String = ""
    var transactionName: String {
        get { expenseName }
        set { expenseName = newValue }
    }
    @Published var amountText: String = ""
    @Published var selectedCategory: ExpenseCategory = .food
    @Published var selectedDate: Date = Date()
    @Published var notes: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    @Published var categories: [ExpenseCategory] = []
    
    private let repoService: TransactionRepoService
    
    init(repoService: TransactionRepoService) {
        self.repoService = repoService
        validateForm()
    }
    
    var formattedDateForDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var hasChanges: Bool {
        return !expenseName.isEmpty || !amountText.isEmpty
    }
    
    var successMessage: String {
        return "Expense added successfully!"
    }
    
    func loadInitialData() {
        categories = ExpenseCategory.userSelectableCategories
        selectedCategory = categories.first ?? .food
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0
    }
    
    func resetForm() {
        expenseName = ""
        amountText = ""
        isSuccess = false
        errorMessage = ""
        validateForm()
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Capability: AddTransactionActions
    func saveTransaction() async {
        await addExpense()
    }
    
    private func addExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let amount = Double(amountText) ?? 0
            let trimmedName = expenseName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await repoService.create(
                name: trimmedName,
                amount: amount,
                categoryRaw: selectedCategory.rawValue,
                date: selectedDate,
                notes: nil // Regular expense does not have notes
            )
            
            isSuccess = true
            
            // Notify that expense data has changed
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
            
        } catch {
            errorMessage = "Failed to add expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Data Models
struct ExpenseInsertData: Codable {
    let name: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case category
        case date
        case userId = "user_id"
    }
}

// MARK: - Error Handling
enum AddExpenseError: LocalizedError {
    case userNotFound
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidData:
            return "Invalid data provided."
        }
    }
}
