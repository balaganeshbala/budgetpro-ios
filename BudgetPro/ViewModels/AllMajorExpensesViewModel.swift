//
//  AllMajorExpensesViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import Foundation
import SwiftUI

// MARK: - All Major Expenses View Model
@MainActor
class AllMajorExpensesViewModel: ObservableObject {
    @Published var majorExpenses: [MajorExpense] = []
    @Published var sortedMajorExpenses: [MajorExpense] = []
    @Published var currentSortType: SortType = .dateNewest
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let supabaseManager = SupabaseManager.shared
    
    init() {
        setupNotificationObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .majorExpenseDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.loadMajorExpenses()
            }
        }
    }
    
    func loadMajorExpenses() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let session = try await supabaseManager.client.auth.session
            let userId = session.user.id
            
            let response: [MajorExpenseResponse] = try await supabaseManager.client
                .from("major_expenses")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .order("date", ascending: false)
                .execute()
                .value
            
            majorExpenses = response.compactMap { responseItem in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                guard let date = dateFormatter.date(from: responseItem.date) else {
                    return nil
                }
                
                return MajorExpense(
                    id: responseItem.id,
                    name: responseItem.name,
                    category: MajorExpenseCategory.from(categoryName: responseItem.category),
                    date: date,
                    amount: responseItem.amount,
                    notes: responseItem.notes
                )
            }
            
            sortMajorExpenses()
            
        } catch {
            errorMessage = "Failed to load major expenses: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func setSortType(_ sortType: SortType) {
        currentSortType = sortType
        sortMajorExpenses()
    }
    
    private func sortMajorExpenses() {
        switch currentSortType {
        case .dateNewest:
            sortedMajorExpenses = majorExpenses.sorted { $0.date > $1.date }
        case .dateOldest:
            sortedMajorExpenses = majorExpenses.sorted { $0.date < $1.date }
        case .amountHighest:
            sortedMajorExpenses = majorExpenses.sorted { $0.amount > $1.amount }
        case .amountLowest:
            sortedMajorExpenses = majorExpenses.sorted { $0.amount < $1.amount }
        }
    }
    
    func refreshData() async {
        await loadMajorExpenses()
    }
}

// MARK: - Data Models
struct MajorExpenseResponse: Codable {
    let id: Int
    let name: String
    let amount: Double
    let category: String
    let date: String
    let notes: String?
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case amount
        case category
        case date
        case notes
        case userId = "user_id"
    }
}
