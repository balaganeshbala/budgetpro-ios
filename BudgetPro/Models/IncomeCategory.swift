//
//  IncomeCategory.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import SwiftUI

enum IncomeCategory: String, CaseIterable {
    case salary
    case freelance
    case business
    case investment
    case rental
    case gift
    case bonus
    case pension
    case dividends
    case interest
    case other
    
    /// Returns all categories except 'other' for user-facing selections
    static var userSelectableCategories: [IncomeCategory] {
        return allCases.filter { $0 != .other }
    }
    
    var displayName: String {
        switch self {
        case .salary: return "Salary"
        case .freelance: return "Freelance"
        case .business: return "Business"
        case .investment: return "Investment"
        case .rental: return "Rental"
        case .gift: return "Gift"
        case .bonus: return "Bonus"
        case .pension: return "Pension"
        case .dividends: return "Dividends"
        case .interest: return "Interest"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .freelance: return "laptopcomputer"
        case .business: return "building.2.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .rental: return "house.and.flag.fill"
        case .gift: return "gift.fill"
        case .bonus: return "star.fill"
        case .pension: return "person.fill.checkmark"
        case .dividends: return "percent"
        case .interest: return "banknote.fill"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .salary: return .blue
        case .freelance: return .purple
        case .business: return .green
        case .investment: return .orange
        case .rental: return .brown
        case .gift: return .pink
        case .bonus: return .yellow
        case .pension: return .gray
        case .dividends: return .cyan
        case .interest: return .mint
        case .other: return .secondary
        }
    }
    
    static func from(categoryName: String) -> IncomeCategory {
        // First try to match exact rawValue (new format)
        if let category = IncomeCategory(rawValue: categoryName) {
            return category
        }
        
        // Fall back to displayName matching (for backward compatibility)
        let lowercased = categoryName.lowercased()
        
        switch lowercased {
        case "salary", "wage", "wages": return .salary
        case "freelance", "freelancing": return .freelance
        case "business": return .business
        case "investment", "investments": return .investment
        case "rental", "rent": return .rental
        case "gift", "gifts": return .gift
        case "bonus": return .bonus
        case "pension": return .pension
        case "dividends", "dividend": return .dividends
        case "interest": return .interest
        default: return .other
        }
    }
}