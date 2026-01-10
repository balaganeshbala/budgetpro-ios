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
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var availableYears: [Int] = []
    @Published var currentSortType: SortType = .dateNewest
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let supabaseManager = SupabaseManager.shared
    private let repoService: DataFetchRepoService
    
    init(repoService: DataFetchRepoService) {
        self.repoService = repoService
        setupAvailableYears()
        setupNotificationObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAvailableYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        // Available years from 2023 to current year + 1 (for future planning)
        availableYears = (2023...currentYear).reversed().map { $0 }
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
            // Construct date range for the selected year
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = selectedYear
            components.month = 1
            components.day = 1
            
            guard let startDate = calendar.date(from: components),
                  let endDate = calendar.date(byAdding: .year, value: 1, to: startDate) else {
                throw NSError(domain: "DateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct date range"])
            }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            // Fetch rows using the repo service with automatic decoding
            let response: [MajorExpense] = try await repoService.fetchAll(
                from: "major_expenses",
                filters: [
                    RepoQueryFilter(column: "date", op: .gte, value: startDateString),
                    RepoQueryFilter(column: "date", op: .lt, value: endDateString)
                ]
            )
            
            majorExpenses = response
            
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


