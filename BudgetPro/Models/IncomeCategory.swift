//
//  IncomeCategory.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import SwiftUI

enum IncomeCategory: String, CaseIterable, CategoryProtocol {
    case salary
    case investment
    case business
    case rental
    case sideHustle
    case service
    case gift
    case pension
    case interest
    case dividend
    case royalties
    case refund
    case benefits
    case rewards
    case other
    
    /// Returns all categories except 'other' for user-facing selections
    static var userSelectableCategories: [IncomeCategory] {
        return allCases.filter { $0 != .other }
    }
    
    var displayName: String {
        switch self {
        case .salary: return "Salary"
        case .investment: return "Investment"
        case .business: return "Business"
        case .rental: return "Rental"
        case .sideHustle: return "Side Hustle"
        case .service: return "Service"
        case .gift: return "Gift"
        case .pension: return "Pension"
        case .interest: return "Interest"
        case .dividend: return "Dividend"
        case .royalties: return "Royalties"
        case .refund: return "Refund"
        case .benefits: return "Benefits"
        case .rewards: return "Rewards"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .salary: return "briefcase.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .business: return "building.2.fill"
        case .rental: return "house.and.flag.fill"
        case .sideHustle: return "laptopcomputer"
        case .service: return "wrench.and.screwdriver.fill"
        case .gift: return "gift.fill"
        case .pension: return "person.fill.checkmark"
        case .interest: return "percent"
        case .dividend: return "dollarsign.circle.fill"
        case .royalties: return "music.note"
        case .refund: return "arrow.counterclockwise.circle.fill"
        case .benefits: return "shield.checkered"
        case .rewards: return "star.fill"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .salary: return .green
        case .investment: return .blue
        case .business: return .orange
        case .rental: return .purple
        case .sideHustle: return .red
        case .service: return Color(.systemTeal)
        case .gift: return .pink
        case .pension: return .indigo
        case .interest: return .yellow
        case .dividend: return .cyan
        case .royalties: return Color(.systemPurple)
        case .refund: return Color(.systemGreen)
        case .benefits: return .mint
        case .rewards: return Color(.systemYellow)
        case .other: return .gray
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
        case "investment", "investments": return .investment
        case "business": return .business
        case "rental", "rent": return .rental
        case "side hustle", "sidehustle", "freelance": return .sideHustle
        case "service", "services": return .service
        case "gift", "gifts": return .gift
        case "pension": return .pension
        case "interest": return .interest
        case "dividend", "dividends": return .dividend
        case "royalties", "royalty": return .royalties
        case "refund", "refunds": return .refund
        case "benefits", "benefit": return .benefits
        case "rewards", "reward": return .rewards
        default: return .other
        }
    }
}
