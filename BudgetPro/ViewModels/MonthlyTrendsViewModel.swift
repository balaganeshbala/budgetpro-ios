//
//  MonthlyTrendsViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh on 06/01/26.
//

import SwiftUI
import Combine

struct MonthlyTrendData: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let year: String
    let date: Date
    let totalExpense: Double
    let totalIncome: Double
    var savings: Double {
        let net = totalIncome - totalExpense
        return max(0, net)
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        return formatter.string(from: date)
    }
}

@MainActor
class MonthlyTrendsViewModel: ObservableObject {
    @Published var trendData: [MonthlyTrendData] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let repoService: DataFetchRepoService
    private let userId: String
    
    // Cache summary data
    private var expenseSummaries: [FinancialMonthlySummary] = []
    private var incomeSummaries: [FinancialMonthlySummary] = []
    
    init(userId: String, repoService: DataFetchRepoService) {
        self.userId = userId
        self.repoService = repoService
    }
    
    // Fetch ONCE
    func fetchAllData() async {
        isLoading = true
        errorMessage = ""
        
        do {
            // 1. Fetch Expense Summaries for user
            let expenseFilters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId)
            ]
            self.expenseSummaries = try await repoService.fetchAll(from: "monthly_expense_summaries", filters: expenseFilters, orderBy: "year")
            
            // 2. Fetch Income Summaries for user
            let incomeFilters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId)
            ]
            self.incomeSummaries = try await repoService.fetchAll(from: "monthly_income_summaries", filters: incomeFilters, orderBy: "year")
            
            // 3. Process Data
            filterData()
            
        } catch {
            print("Error loading trend data: \(error)")
            errorMessage = "Failed to load trend data. Please try again."
        }
        
        isLoading = false
    }
    
    // Filter locally without network call
    private func filterData() {
        let calendar = Calendar.current
        // Set endDate to previous month to exclude current incomplete month
        let endDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        // Always show last 24 months
        let startDate = calendar.date(byAdding: .year, value: -2, to: endDate) ?? endDate
        processData(startDate: startDate, endDate: endDate)
    }
    
    private func processData(startDate: Date, endDate: Date) {
        var data: [MonthlyTrendData] = []
        
        var cal = Calendar.current
        cal.timeZone = TimeZone.current 

        var currentDate = startDate.startOfMonth
        let end = endDate.endOfMonth
        
        while currentDate <= end {
            let month = cal.component(.month, from: currentDate)
            let year = cal.component(.year, from: currentDate)
            
            let expenseSum = expenseSummaries.first { $0.year == year && $0.month == month }
            let incomeSum = incomeSummaries.first { $0.year == year && $0.month == month }
            
            let totalExpense = expenseSum?.totalAmount ?? 0
            let totalIncome = incomeSum?.totalAmount ?? 0
            
            let monthName = DateFormatter().monthSymbols[month - 1]
            let shortYear = String(String(year).suffix(2))
            
            data.append(MonthlyTrendData(
                month: monthName,
                year: shortYear,
                date: currentDate,
                totalExpense: totalExpense,
                totalIncome: totalIncome
            ))
            
            // Next month
            guard let next = cal.date(byAdding: .month, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        self.trendData = data
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth) ?? self
    }
}
