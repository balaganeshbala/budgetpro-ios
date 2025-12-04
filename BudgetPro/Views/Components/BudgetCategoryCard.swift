//
//  BudgetCategoryCard.swift
//  BudgetPro
//
//  Created by Balaganesh S on 04/12/25.
//

import SwiftUI

struct BudgetCategoryCard: View {
    let category: BudgetCategory
    let totalBudget: Double
    
    private var percentageSpent: Double {
        category.budget > 0 ? (category.spent / category.budget) : 0
    }
    
    private var percentOfTotal: Double {
        totalBudget > 0 ? (category.budget / totalBudget * 100) : 0
    }
    
    private var statusInfo: (text: String, color: Color) {
        if category.budget == 0 && category.spent > 0 {
            return ("Unplanned", .primary)
        } else if category.budget == 0 {
            return ("No Budget", .secondaryText)
        } else if percentageSpent > 1 {
            return ("Overspent", .adaptiveRed)
        } else {
            return ("On Track", .successColor)
        }
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                // Header row
                HStack {
                    // Category icon and name
                    HStack(spacing: 12) {
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 16))
                                    .foregroundColor(categoryColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.appFont(16, weight: .medium))
                                .foregroundColor(.primaryText)
                            
                            Text("\(String(format: percentOfTotal < 1 && percentOfTotal > 0 ? "%.2f" : "%.0f", percentOfTotal))% of total budget")
                                .font(.appFont(12))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(statusInfo.text)
                        .font(.appFont(11, weight: .medium))
                        .foregroundColor(statusInfo.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusInfo.color.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // Budget amounts
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(Int(category.budget))")
                            .font(.appFont(16, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(Int(category.budget - category.spent))")
                            .font(.appFont(16, weight: .semibold))
                            .foregroundColor(percentageSpent > 1 ? .adaptiveRed : .primaryText)
                    }
                }
                
                // Progress bar
                if category.budget > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondarySystemFill)
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(percentageSpent > 1 ? Color.adaptiveRed : Color.adaptiveGreen)
                                .frame(width: min(geometry.size.width, geometry.size.width * percentageSpent), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }
    
    // Helper computed properties for category styling
    private var categoryColor: Color {
        return ExpenseCategory.from(categoryName: category.name).color
    }
    
    private var categoryIcon: String {
        return ExpenseCategory.from(categoryName: category.name).iconName
    }
}
