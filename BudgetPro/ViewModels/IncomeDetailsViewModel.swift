//
//  IncomeDetailsViewModel.swift
//  BudgetPro
//
//  Created by Claude on 04/08/25.
//

import Foundation

@MainActor
class IncomeDetailsViewModel: ObservableObject, TransactionFormViewModelProtocol {
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
    
    private let supabaseManager = SupabaseManager.shared
    
    init(income: Income) {
        self.originalIncome = income
        self.originalSource = income.source
        self.originalAmount = income.amount
        self.originalDate = income.date
        self.originalCategory = income.category
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
    
    func saveTransaction() async {
        // Not applicable for update mode
    }
    
    func updateTransaction() async {
        await updateIncome()
    }
    
    func deleteTransaction() async {
        await deleteIncome()
    }
    
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
    
    func updateIncome() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw IncomeDetailsError.userNotFound
            }
            
            let amount = Double(amountText) ?? 0
            let dateString = formatDateForDatabase(selectedDate)
            
            // Update the income in database
            try await supabaseManager.client
                .from("incomes")
                .update([
                    "source": incomeName.trimmingCharacters(in: .whitespacesAndNewlines),
                    "amount": amount.rawValue,
                    "category": selectedCategory.rawValue,
                    "date": dateString
                ])
                .eq("id", value: originalIncome.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Income updated successfully!"
            isSuccess = true
            
            // Notify that income data has changed
            NotificationCenter.default.post(name: .incomeDataChanged, object: nil)
            
        } catch {
            print("Update income error: \(error)")
            errorMessage = "Failed to update income: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteIncome() async {
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw IncomeDetailsError.userNotFound
            }
            
            // Delete the income from database
            try await supabaseManager.client
                .from("incomes")
                .delete()
                .eq("id", value: originalIncome.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Income deleted successfully!"
            isSuccess = true
            
            // Notify that income data has changed
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
