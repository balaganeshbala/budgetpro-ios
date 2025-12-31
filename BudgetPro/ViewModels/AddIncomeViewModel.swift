//
//  AddIncomeViewModel.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let incomeDataChanged = Notification.Name("incomeDataChanged")
}

// MARK: - Add Income View Model
@MainActor
class AddIncomeViewModel: ObservableObject, TransactionFormStateProtocol, AddTransactionActions {
    @Published var incomeName: String = ""
    @Published var amountText: String = ""
    @Published var selectedCategory: IncomeCategory = .salary
    @Published var selectedDate: Date = Date()
    @Published var notes: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    @Published var categories: [IncomeCategory] = []
    
    private let repoService: TransactionRepoService
    
    // Protocol conformance
    var transactionName: String {
        get { incomeName }
        set { incomeName = newValue }
    }
    
    var hasChanges: Bool {
        return !incomeName.isEmpty || !amountText.isEmpty
    }
    
    var successMessage: String {
        return "Income added successfully!"
    }
    
    init(repoService: TransactionRepoService) {
        self.repoService = repoService
        validateForm()
    }
    
    var formattedDateForDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    func loadInitialData() {
        categories = IncomeCategory.userSelectableCategories
        selectedCategory = categories.first ?? .salary
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !incomeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0
    }
    
    func resetForm() {
        incomeName = ""
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
        await addIncome()
    }
    
    private func addIncome() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let amount = Double(amountText) ?? 0
            let trimmedName = incomeName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await repoService.create(
                name: trimmedName,
                amount: amount,
                categoryRaw: selectedCategory.rawValue,
                date: selectedDate,
                notes: nil // Income does not use notes
            )
            
            isSuccess = true
            
            // Notify that income data has changed
            NotificationCenter.default.post(name: .incomeDataChanged, object: nil)
            
        } catch {
            errorMessage = "Failed to add income: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Data Models


// MARK: - Error Handling
enum AddIncomeError: LocalizedError {
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
