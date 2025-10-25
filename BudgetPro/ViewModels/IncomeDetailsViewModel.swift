//
//  IncomeDetailsViewModel.swift
//  BudgetPro
//
//  Created by Claude on 04/08/25.
//

import Foundation

@MainActor
class IncomeDetailsViewModel: ObservableObject, TransactionFormStateProtocol, EditTransactionActions {
    @Published var incomeName: String = ""
    var transactionName: String {
        get { incomeName }
        set { incomeName = newValue }
    }
    @Published var amountText: String = ""
    @Published var selectedCategory: IncomeCategory = .salary
    @Published var selectedDate: Date = Date() {
        didSet {
            validateForm()
        }
    }
    @Published var notes: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    // Original values for comparison
    private let originalIncome: Income
    private var originalSource: String
    private var originalAmount: Double
    private var originalCategory: IncomeCategory
    private var originalDate: Date
    
    // Repository service abstraction
    private let repoService: TransactionRepoService
    
    init(income: Income, repoService: TransactionRepoService) {
        self.originalIncome = income
        self.originalSource = income.source
        self.originalAmount = income.amount
        self.originalDate = income.date
        self.originalCategory = income.category
        self.repoService = repoService
    }
    
    var hasChanges: Bool {
        let currentAmount = Double(amountText) ?? 0
        return incomeName != originalSource ||
               currentAmount != originalAmount ||
               selectedCategory != originalCategory ||
               !Calendar.current.isDate(selectedDate, inSameDayAs: originalDate)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var formattedDateForDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Capabilities
    
    func updateTransaction() async {
        await updateIncome()
    }
    
    func deleteTransaction() async {
        await deleteIncome()
    }
    
    // MARK: - State lifecycle
    
    func loadInitialData() {
        loadIncomeData()
    }
    
    func resetForm() {
        // Not applicable for update mode
    }
    
    func loadIncomeData() {
        incomeName = originalSource
        amountText = originalAmount > 0 ? String(format: "%.2f", originalAmount) : ""
        selectedCategory = originalCategory
        selectedDate = originalDate
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !incomeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0 &&
                      hasChanges
    }
    
    private func updateIncome() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let amount = Double(amountText) ?? 0
            let trimmedName = incomeName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await repoService.update(
                id: originalIncome.id,
                name: trimmedName,
                amount: amount,
                categoryRaw: selectedCategory.rawValue,
                date: selectedDate,
                notes: nil // Income model does not include notes
            )
            
            successMessage = "Income updated successfully!"
            isSuccess = true
            
            NotificationCenter.default.post(name: .incomeDataChanged, object: nil)
            
        } catch {
            print("Update income error: \(error)")
            errorMessage = "Failed to update income: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func deleteIncome() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await repoService.delete(id: originalIncome.id)
            
            successMessage = "Income deleted successfully!"
            isSuccess = true
            
            NotificationCenter.default.post(name: .incomeDataChanged, object: nil)
            
        } catch {
            print("Delete income error: \(error)")
            errorMessage = "Failed to delete income: \(error.localizedDescription)"
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

enum IncomeDetailsError: LocalizedError {
    case userNotFound
    case invalidData
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .invalidData:
            return "Invalid income data. Please check your inputs."
        case .updateFailed:
            return "Failed to update income. Please try again."
        case .deleteFailed:
            return "Failed to delete income. Please try again."
        }
    }
}

