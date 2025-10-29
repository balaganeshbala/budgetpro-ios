//
//  CommonHelpers.swift
//  BudgetPro
//
//  Created by Balaganesh S on 05/08/25.
//

import SwiftUI
import Foundation

// MARK: - Common Helper Functions
struct CommonHelpers {
    
    // MARK: - Number Formatting
    
    /// Formats a Double amount to a string with proper number formatting
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted string representation of the amount
    static func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    // MARK: - Date Utilities
    
    /// Checks if the given month and year represent the current month
    /// - Parameters:
    ///   - month: Month string (e.g., "Jan", "Feb", etc.)
    ///   - year: Year string (e.g., "2024")
    /// - Returns: True if the month/year combination represents the current month
    static func isCurrentMonth(_ month: String, _ year: String) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Month names array
        let monthNames: [String] = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ]
        
        guard let monthIndex = monthNames.firstIndex(of: month),
              let yearInt = Int(year) else {
            return false
        }
        
        return (monthIndex + 1) == currentMonth && yearInt == currentYear
    }
    
    // MARK: - Savings Analysis Helpers
    
    /// Returns the appropriate color for a given savings rate
    /// - Parameter rate: The savings rate as a percentage
    /// - Returns: Color representing the savings rate quality
    static func getSavingsRateColor(_ rate: Double) -> Color {
        if rate < 0 { return .red }
        if rate < 10 { return .adaptiveRed }
        if rate < 20 { return .orange }
        return .adaptiveGreen
    }
    
    /// Returns the appropriate SF Symbol icon for a given savings rate
    /// - Parameter rate: The savings rate as a percentage
    /// - Returns: SF Symbol name representing the savings rate quality
    static func getSavingsRateIcon(_ rate: Double) -> String {
        if rate < 0 { return "exclamationmark.triangle.fill" }
        if rate < 10 { return "chart.line.downtrend.xyaxis" }
        if rate < 20 { return "minus" }
        return "chart.line.uptrend.xyaxis"
    }
    
    /// Returns an appropriate message for a given savings rate
    /// - Parameter rate: The savings rate as a percentage
    /// - Returns: User-friendly message describing the savings rate
    static func getSavingsRateMessage(_ rate: Double) -> String {
        if rate < 0 {
            return "Warning: You're spending more than you earn."
        }
        if rate < 10 {
            return "Your savings rate is low. Try to increase it to at least 10-15%."
        }
        if rate < 20 {
            return "Good progress! Try to reach the recommended 20% savings rate."
        }
        return "Excellent! You're meeting or exceeding the recommended savings rate."
    }
    
    // MARK: - Budget Analysis Helpers
    
    /// Calculates effective expenses based on current month status
    /// - Parameters:
    ///   - totalExpenses: Actual total expenses
    ///   - totalBudget: Total budget amount
    ///   - isCurrentMonth: Whether this is the current month
    /// - Returns: Effective expenses (max of expenses and budget for current month)
    static func getEffectiveExpenses(totalExpenses: Double, totalBudget: Double, isCurrentMonth: Bool) -> Double {
        if isCurrentMonth {
            return max(totalExpenses, totalBudget)
        } else {
            return totalExpenses
        }
    }
    
    // MARK: - Currency Formatting
    
    /// Formats amount with currency symbol
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted string with currency symbol
    static func formatCurrency(_ amount: Double) -> String {
        return "₹\(formatAmount(amount))"
    }
    
    /// Formats amount with currency symbol and sign prefix
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - showSign: Whether to show + or - sign
    /// - Returns: Formatted string with currency symbol and optional sign
    static func formatCurrencyWithSign(_ amount: Double, showNegative: Bool = true) -> String {
        let formattedAmount = formatAmount(abs(amount))
        if amount > 0 || showNegative {
            let sign = amount >= 0 ? "+" : "-"
            return "\(sign)₹\(formattedAmount)"
        }
        return "₹0"
    }
}

// MARK: - Savings Analysis Extensions
extension CommonHelpers {
    
    /// Generates recommendations based on savings rate and budget performance
    /// - Parameters:
    ///   - savingsRate: Current savings rate percentage
    ///   - totalExpenses: Total expenses amount
    ///   - totalBudget: Total budget amount
    /// - Returns: Array of recommendation tuples
    static func getSavingsRecommendations(
        savingsRate: Double,
        totalExpenses: Double,
        totalBudget: Double
    ) -> [(title: String, description: String, icon: String, color: Color)] {
        var recommendations: [(title: String, description: String, icon: String, color: Color)] = []
        
        // Primary savings rate recommendations
        if savingsRate < 0 {
            recommendations.append((
                title: "Urgent: Reduce Expenses",
                description: "Your expenses exceed your income. Review and cut non-essential spending immediately.",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        } else if savingsRate < 10 {
            recommendations.append((
                title: "Increase Savings Rate",
                description: "Aim to save at least 10-15% of your income. Consider reducing discretionary spending.",
                icon: "arrow.up.circle.fill",
                color: .orange
            ))
        } else if savingsRate < 20 {
            recommendations.append((
                title: "Good Progress",
                description: "You're saving well! Try to reach the recommended 20% savings rate for better financial security.",
                icon: "checkmark.circle.fill",
                color: .primary
            ))
        } else {
            recommendations.append((
                title: "Excellent Savings",
                description: "Great job! You're exceeding the recommended savings rate. Consider investing for long-term growth.",
                icon: "star.fill",
                color: .green
            ))
        }
        
        // Budget performance recommendations
        if totalExpenses > totalBudget {
            recommendations.append((
                title: "Budget Overspend",
                description: "You're spending more than budgeted. Review your categories and adjust your budget or spending habits.",
                icon: "chart.line.downtrend.xyaxis",
                color: .red
            ))
        }
        
        // General financial advice
        recommendations.append((
            title: "Emergency Fund",
            description: "Ensure you have 3-6 months of expenses saved as an emergency fund for unexpected situations.",
            icon: "shield.lefthalf.filled",
            color: .blue
        ))
        
        return recommendations
    }
}
