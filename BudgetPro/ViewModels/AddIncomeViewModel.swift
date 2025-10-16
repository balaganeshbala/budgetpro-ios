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
    
    private let supabaseManager = SupabaseManager.shared
    
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
            // Ensure user is authenticated before proceeding
            let session = try await supabaseManager.client.auth.session
            let userId = session.user.id
            
            let amount = Double(amountText) ?? 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            
            let incomeData = IncomeInsertData(
                source: incomeName.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                category: selectedCategory.rawValue,
                date: dateFormatter.string(from: selectedDate),
                userId: userId.uuidString
            )
            
            try await supabaseManager.client
                .from("incomes")
                .insert(incomeData)
                .execute()
            
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
struct IncomeInsertData: Codable {
    let source: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case source
        case amount
        case category
        case date
        case userId = "user_id"
    }
}

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

