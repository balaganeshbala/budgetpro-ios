//
//  FinancialDataTool.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import Foundation

// A helper tool that the AI (or Mock AI) uses to fetch actual data from the app's repositories.
class FinancialDataTool {

    private let repoService: DataFetchRepoService
    private let userId: String
    
    init(repoService: DataFetchRepoService, userId: String) {
        self.repoService = repoService
        self.userId = userId
    }
    
    // Calculates total expenses matching the criteria
    func getExpensesTotal(category: String?, month: Int?, year: Int?) async -> Double {
        do {
            var filters = [RepoQueryFilter]()
            
            // Always filter by user
            filters.append(RepoQueryFilter(column: "user_id", op: .eq, value: userId))
            
            // Fetch all expenses for user (Mock implementation limitation: handling Date filtering in memory for simplicity 
            // because Supabase date filtering on stored strings requires precise formatting)
            // In a production app, we would push date filters to the DB.
            let responses: [ExpenseResponse] = try await repoService.fetchAll(from: "expenses", filters: filters)
            
            // Filter in memory
            let filtered = responses.filter { expense in
                var matches = true
                
                // Date Filtering
                if let month = month, let year = year {
                    // expense.date is "YYYY-MM-DD"
                    // Simple string parsing
                    let components = expense.date.split(separator: "-")
                    if components.count == 3 {
                        if let expYear = Int(components[0]), let expMonth = Int(components[1]) {
                             if expYear != year || expMonth != month {
                                 matches = false
                             }
                        }
                    }
                }
                
                // Category Filtering
                if let category = category, matches {
                     // Normalize strings
                    let expCat = expense.category.lowercased().trimmingCharacters(in: .whitespaces)
                    let queryCat = category.lowercased().trimmingCharacters(in: .whitespaces)
                    
                    // Allow partial match
                    if !expCat.contains(queryCat) {
                        matches = false
                    }
                }
                
                return matches
            }
            
            return filtered.reduce(0) { $0 + $1.amount }
        } catch {
            print("Error fetching expenses: \(error)")
            return 0.0
        }
    }

    // Calculates total income matching the criteria
    func getIncomeTotal(category: String?, month: Int?, year: Int?) async -> Double {
        do {
            var filters = [RepoQueryFilter]()
            filters.append(RepoQueryFilter(column: "user_id", op: .eq, value: userId))
            
            let responses: [IncomeResponse] = try await repoService.fetchAll(from: "incomes", filters: filters)
            
            let filtered = responses.filter { income in
                var matches = true
                
                // Date Filtering
                if let month = month, let year = year {
                    let components = income.date.split(separator: "-")
                    if components.count == 3 {
                        if let incYear = Int(components[0]), let incMonth = Int(components[1]) {
                             if incYear != year || incMonth != month {
                                 matches = false
                             }
                        }
                    }
                }
                
                // Category Filtering
                if let category = category, matches {
                    let incCat = income.category.lowercased().trimmingCharacters(in: .whitespaces)
                    let queryCat = category.lowercased().trimmingCharacters(in: .whitespaces)
                    if !incCat.contains(queryCat) {
                        matches = false
                    }
                }
                
                return matches
            }
            
            return filtered.reduce(0) { $0 + $1.amount }
        } catch {
            print("Error fetching income: \(error)")
            return 0.0
        }
    }
    
    // Fetches financial goals and their status
    func getFinancialGoals() async -> String {
        do {
            var filters = [RepoQueryFilter]()
            filters.append(RepoQueryFilter(column: "user_id", op: .eq, value: userId))
            
            // Note: Assuming "financial_goals" is the table name based on context
            // We need to use FinancialGoal model which is Codable
            // Let's assume the Repo can fetch it if tables match
            // IMPORTANT: The table name in Supabase needs to match what repo expects or what exists.
            // Based on earlier context, FinancialGoal struct CodingKeys map to 'goal_id', etc.
            
            let goals: [FinancialGoal] = try await repoService.fetchAll(from: "financial_goals", filters: filters)
            
            if goals.isEmpty {
                return "No financial goals found."
            }
            
            // Format into a readable string for the AI
            let goalStrings = goals.map { goal in
                let progress = (goal.contributions?.reduce(0) { $0 + $1.amount } ?? 0)
                return "- \(goal.title): Target ₹\(goal.targetAmount), Saved ₹\(progress), Status: \(goal.status.rawValue)"
            }
            
            return goalStrings.joined(separator: "\n")
        } catch {
            print("Error fetching goals: \(error)")
            // Return empty string or error message so AI knows access failed
            return "Error retrieving goals. (Table 'financial_goals' might be missing or inaccessible)"
        }
    }
    
    // Fetches budget details (Categories, Budgeted, Spent) for a given month
    func getBudgetCategories(month: Int, year: Int) async -> String {
        do {
            let targetDate = CommonHelpers.getMonthStartDate(month: month, year: year)
            let filters = [
                RepoQueryFilter(column: "user_id", op: .eq, value: userId),
                RepoQueryFilter(column: "date", op: .eq, value: targetDate)
            ]
            let budgetResponse: [BudgetResponse] = try await repoService.fetchAll(from: "budget", filters: filters)
            
            // We also need expenses for this month to calculate spent vs budget
            // Reusing local logic similar to HomeViewModel to be self-contained in tool
             var expFilters = [RepoQueryFilter]()
             expFilters.append(RepoQueryFilter(column: "user_id", op: .eq, value: userId))
             // ... Date filtering requires fetching all as before or specific range if DB supports
             let allExpenses: [ExpenseResponse] = try await repoService.fetchAll(from: "expenses", filters: expFilters)
            
            // Filter expenses for month/year in memory (same as getExpensesTotal)
            let monthExpenses = allExpenses.filter { expense in
                let components = expense.date.split(separator: "-")
                if components.count == 3, let expYear = Int(components[0]), let expMonth = Int(components[1]) {
                    return expYear == year && expMonth == month
                }
                return false
            }
            
            // Group expenses
            let expensesByCategory = Dictionary(grouping: monthExpenses) { $0.category } // Category Name
            
            if budgetResponse.isEmpty && monthExpenses.isEmpty {
                 return "No budget or expenses found for this month."
            }
            
            var reportLines: [String] = []
            reportLines.append("Budget Report for \(month)/\(year):")
            
            // 1. Process Set Budgets
            for budgetItem in budgetResponse {
                // Defensive: Ensure category exists or fallback
                let catName = budgetItem.category
                let budgetAmount = budgetItem.amount
                
                // Find matching expenses (loosely matching category name)
                
                let spent = expensesByCategory[budgetItem.category]?.reduce(0) { $0 + $1.amount } ?? 0
                let remaining = budgetAmount - spent
                let status = spent > budgetAmount ? "Overspent" : "Under"
                
                reportLines.append("- \(catName): Budget ₹\(budgetAmount), Spent ₹\(spent), Remaining: ₹\(remaining) (\(status))")
            }
            
            // 2. Identify Unbudgeted Spending
            let budgetedCategories = Set(budgetResponse.map { $0.category })
            for (catRaw, expenses) in expensesByCategory {
                if !budgetedCategories.contains(catRaw) {
                    let total = expenses.reduce(0) { $0 + $1.amount }
                    reportLines.append("- \(catRaw): No Budget, Spent ₹\(total) (Unplanned)")
                }
            }
            
            return reportLines.joined(separator: "\n")
            
        } catch {
             print("Error fetching budget: \(error)")
             return "Error fetching budget details."
        }
    }
}
