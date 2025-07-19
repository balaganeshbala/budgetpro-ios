//
//  AddExpenseViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 17/07/25.
//

import Foundation
import SwiftUI

// MARK: - Add Expense View Model
@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var expenseName: String = ""
    @Published var amountText: String = ""
    @Published var selectedCategory: ExpenseCategory = .food
    @Published var selectedDate: Date = Date()
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isSuccess = false
    @Published var isFormValid = false
    
    @Published var categories: [ExpenseCategory] = []
    
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
    
    func loadInitialData() {
        categories = ExpenseCategory.allCases.filter { $0 != .unknown }
        selectedCategory = categories.first ?? .food
        validateForm()
    }
    
    func validateForm() {
        let amount = Double(amountText) ?? 0
        isFormValid = !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      amount > 0
    }
    
    func addExpense() async {
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
            
            let expenseData = ExpenseInsertData(
                name: expenseName,
                amount: amount,
                category: selectedCategory.displayName,
                date: dateFormatter.string(from: selectedDate),
                userId: userId.uuidString
            )
            
            try await supabaseManager.client
                .from("expenses")
                .insert(expenseData)
                .execute()
            
            isSuccess = true
            
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
