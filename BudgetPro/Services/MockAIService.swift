//
//  MockAIService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import Foundation

class MockAIService: AIService {
    
    private let tool: FinancialDataTool
    
    init(tool: FinancialDataTool) {
        self.tool = tool
    }
    
    func sendMessage(_ text: String) async throws -> AIResponse {
        // Pseudo-delay to simulate network
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 1. Parse Intent (Regex)
        let lowerText = text.lowercased()
        
        // Pattern: "How much did I spend on [Category]"
        if lowerText.contains("spend") || lowerText.contains("expense") {
            // Check for category
            var category: String? = nil
            let categories = ["food", "travel", "housing", "entertainment", "groceries", "fuel", "shopping"]
            
            for cat in categories {
                if lowerText.contains(cat) {
                    category = cat
                    break
                }
            }
            
            // Check for Date (Simple: "last month", "this month")
            // Default to current month if not specified
            let calendar = Calendar.current
            let now = Date()
            var month = calendar.component(.month, from: now)
            var year = calendar.component(.year, from: now)
            
            if lowerText.contains("last month") {
                if let date = calendar.date(byAdding: .month, value: -1, to: now) {
                    month = calendar.component(.month, from: date)
                    year = calendar.component(.year, from: date)
                }
            }
            
            // Call Tool
            // If no category found, maybe they want total?
            // "How much did I spend last month" -> Total
            // "How much on food" -> Category
            
            let total = await tool.getExpensesTotal(category: category, month: month, year: year)
            let formattedAmount = CommonHelpers.formatCurrency(total)
            let monthName = DateFormatter().monthSymbols[month - 1]
            
            if let cat = category {
                return AIResponse(text: "You spent \(formattedAmount) on \(cat.capitalized) in \(monthName) \(year).", isError: false)
            } else {
                 return AIResponse(text: "Your total spending in \(monthName) \(year) was \(formattedAmount).", isError: false)
            }
        }
        
        // Fallback
        return AIResponse(text: "I can help you track expenses. Try asking 'How much did I spend on food last month?'", isError: false)
    }
}
