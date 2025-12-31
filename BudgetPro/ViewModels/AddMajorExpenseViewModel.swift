//
//  AddMajorExpenseViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let majorExpenseDataChanged = Notification.Name("majorExpenseDataChanged")
}

// MARK: - Add Major Expense View Model
@MainActor
class AddMajorExpenseViewModel: ObservableObject, TransactionFormStateProtocol, AddTransactionActions {
    @Published var expenseName: String = ""
    var transactionName: String {
        get { expenseName }
        set { expenseName = newValue }
    }
    @Published var amountText: String = ""
    @Published var selectedCategory: MajorExpenseCategory = .other
    @Published var selectedDate: Date = Date()
    @Published var notes: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    @Published var categories: [MajorExpenseCategory] = []
    
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
        return !expenseName.isEmpty || !amountText.isEmpty || !notes.isEmpty
    }
    
    var successMessage: String {
        return "Major expense added successfully!"
    }
    
    func loadInitialData() {
        categories = MajorExpenseCategory.allCases
        selectedCategory = categories.first ?? .other
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
        notes = ""
        isSuccess = false
        errorMessage = ""
        validateForm()
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Capability: AddTransactionActions
    func saveTransaction() async {
        await addMajorExpense()
    }
    
    private func addMajorExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let amount = Double(amountText) ?? 0
            let trimmedName = expenseName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let notesValue = trimmedNotes.isEmpty ? nil : trimmedNotes
            
            try await repoService.create(
                name: trimmedName,
                amount: amount,
                categoryRaw: selectedCategory.rawValue,
                date: selectedDate,
                notes: notesValue
            )
            
            isSuccess = true
            
            // Notify that major expense data has changed
            NotificationCenter.default.post(name: .majorExpenseDataChanged, object: nil)
            
        } catch {
            errorMessage = "Failed to add major expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Data Models


// MARK: - Error Handling
enum AddMajorExpenseError: LocalizedError {
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
