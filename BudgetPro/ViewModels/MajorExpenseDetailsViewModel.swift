//
//  MajorExpenseDetailsViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import Foundation

@MainActor
class MajorExpenseDetailsViewModel: ObservableObject, TransactionFormStateProtocol, EditTransactionActions {
    @Published var expenseName: String = ""
    var transactionName: String {
        get { expenseName }
        set { expenseName = newValue }
    }
    @Published var amountText: String = ""
    @Published var selectedCategory: MajorExpenseCategory = .other
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
    private let originalMajorExpense: MajorExpense
    private var originalName: String
    private var originalAmount: Double
    private var originalCategory: MajorExpenseCategory
    private var originalDate: Date
    private var originalNotes: String?
    
    private let supabaseManager = SupabaseManager.shared
    
    init(majorExpense: MajorExpense) {
        self.originalMajorExpense = majorExpense
        self.originalName = majorExpense.name
        self.originalAmount = majorExpense.amount
        self.originalDate = majorExpense.date
        self.originalCategory = majorExpense.category
        self.originalNotes = majorExpense.notes
    }
    
    var hasChanges: Bool {
        let currentAmount = Double(amountText) ?? 0
        return expenseName != originalName ||
               currentAmount != originalAmount ||
               selectedCategory != originalCategory ||
               !Calendar.current.isDate(selectedDate, inSameDayAs: originalDate) ||
               notes != (originalNotes ?? "")
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
        await updateMajorExpense()
    }
    
    func deleteTransaction() async {
        await deleteMajorExpense()
    }
    
    // MARK: - State lifecycle
    
    func loadInitialData() {
        loadMajorExpenseData()
    }
    
    func resetForm() {
        // Not applicable for update mode
    }
    
    func loadMajorExpenseData() {
        expenseName = originalName
        amountText = originalAmount > 0 ? String(format: "%.2f", originalAmount) : ""
        selectedCategory = originalCategory
        selectedDate = originalDate
        notes = originalNotes ?? ""
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0 &&
                      hasChanges
    }
    
    private func updateMajorExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw MajorExpenseDetailsError.userNotFound
            }
            
            let amount = Double(amountText) ?? 0
            let dateString = formatDateForDatabase(selectedDate)
            let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await supabaseManager.client
                .from("major_expenses")
                .update([
                    "name": expenseName.trimmingCharacters(in: .whitespacesAndNewlines),
                    "amount": amount.rawValue,
                    "category": selectedCategory.rawValue,
                    "date": dateString,
                    "notes": notesValue
                ])
                .eq("id", value: originalMajorExpense.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Major expense updated successfully!"
            isSuccess = true
            
            NotificationCenter.default.post(name: .majorExpenseDataChanged, object: nil)
            
        } catch {
            print("Update major expense error: \(error)")
            errorMessage = "Failed to update major expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func deleteMajorExpense() async {
        isLoading = true
        errorMessage = ""
        
        do {
            guard let userId = supabaseManager.currentUser?.id else {
                throw MajorExpenseDetailsError.userNotFound
            }
            
            try await supabaseManager.client
                .from("major_expenses")
                .delete()
                .eq("id", value: originalMajorExpense.id)
                .eq("user_id", value: userId)
                .execute()
            
            successMessage = "Major expense deleted successfully!"
            isSuccess = true
            
            NotificationCenter.default.post(name: .majorExpenseDataChanged, object: nil)
            
        } catch {
            print("Delete major expense error: \(error)")
            errorMessage = "Failed to delete major expense: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func formatDateForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Errors

enum MajorExpenseDetailsError: LocalizedError {
    case userNotFound
    case invalidData
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .invalidData:
            return "Invalid major expense data. Please check your inputs."
        case .updateFailed:
            return "Failed to update major expense. Please try again."
        case .deleteFailed:
            return "Failed to delete major expense. Please try again."
        }
    }
}

