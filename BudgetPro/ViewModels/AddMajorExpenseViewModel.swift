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
class AddMajorExpenseViewModel: ObservableObject, MajorExpenseFormViewModelProtocol {
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
    
    private let supabaseManager = SupabaseManager.shared
    
    init() {
        validateForm()
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
    
    func saveTransaction() async {
        await addMajorExpense()
    }
    
    func updateTransaction() async {
        // Not applicable for add mode
    }
    
    func deleteTransaction() async {
        // Not applicable for add mode
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    func addMajorExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Ensure user is authenticated before proceeding
            let session = try await supabaseManager.client.auth.session
            let userId = session.user.id
            
            let amount = Double(amountText) ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            
            let majorExpenseData = MajorExpenseInsertData(
                name: expenseName.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                category: selectedCategory.rawValue,
                date: dateFormatter.string(from: selectedDate),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: userId.uuidString
            )
            
            try await supabaseManager.client
                .from("major_expenses")
                .insert(majorExpenseData)
                .execute()
            
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
struct MajorExpenseInsertData: Codable {
    let name: String
    let amount: Double
    let category: String
    let date: String
    let notes: String?
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case category
        case date
        case notes
        case userId = "user_id"
    }
}

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