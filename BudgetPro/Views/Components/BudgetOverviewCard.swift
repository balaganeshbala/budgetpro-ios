//
//  BudgetOverviewCard.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/10/25.
//

import SwiftUI

// MARK: - Budget Overview Card Component

struct CategoryBudgetOverviewCard: View {
    let title: String?
    let totalBudget: Double
    let totalSpent: Double
    
    init(
        title: String? = nil,
        totalBudget: Double,
        totalSpent: Double
    ) {
        self.title = title
        self.totalBudget = totalBudget
        self.totalSpent = totalSpent
    }
    
    private var remainingBudget: Double {
        totalBudget - totalSpent
    }
    
    private var isOverBudget: Bool {
        totalSpent > totalBudget
    }
    
    private var usagePercentage: Int {
        Int((totalSpent / max(totalBudget, 1)) * 100)
    }
    
    private var usageBasedColor: Color {
        isOverBudget ? .adaptiveRed : usagePercentage > 80 ? .warningColor : .adaptiveGreen
    }
    
    private var spentBasedColor: Color {
        isOverBudget ? .adaptiveRed : .primaryText
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            if title != nil {
                HStack {
                    if let title = title {
                        Text(title)
                            .font(.appFont(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                    }
                }
            }
            
            // Budget content
            VStack(spacing: 20) {
                // Remaining Amount - Highlighted at the top
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isOverBudget ? "Overspent": "Remaining Budget")
                            .font(.appFont(18, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(CommonHelpers.formatAmount(abs(remainingBudget)))")
                            .font(.appFont(30, weight: .bold))
                            .foregroundStyle(spentBasedColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        // Total Budget
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.appFont(14))
                                .foregroundColor(.secondaryText)
                            
                            Text("₹\(CommonHelpers.formatAmount(totalBudget))")
                                .font(.appFont(20, weight: .semibold))
                                .foregroundColor(.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(width: 1, height: 40)
                        
                        // Total Spent
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Spent")
                                .font(.appFont(14))
                                .foregroundColor(.secondaryText)
                            
                            Text("₹\(CommonHelpers.formatAmount(totalSpent))")
                                .font(.appFont(20, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Progress Bar with Percentage
                if totalBudget > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Budget Usage")
                                .font(.appFont(14, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Text("\(usagePercentage)%")
                                .font(.appFont(16, weight: .bold))
                                .foregroundColor(isOverBudget ? .adaptiveRed : usagePercentage > 80 ? .warningColor : .adaptiveGreen)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondarySystemFill)
                                    .frame(height: 10)
                                    .cornerRadius(5)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                usageBasedColor,
                                                usageBasedColor.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(geometry.size.width, geometry.size.width * (totalSpent / max(totalBudget, 1))), height: 10)
                                    .cornerRadius(5)
                                    .animation(.easeInOut(duration: 0.5), value: totalSpent)
                            }
                        }
                        .frame(height: 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    VStack {
        CategoryBudgetOverviewCard(totalBudget: 150000, totalSpent: 165000)
        
        CategoryBudgetOverviewCard(title: "Overview", totalBudget: 120000, totalSpent: 95000)
        
        Spacer()
        
    }
}

#Preview {
    VStack {
        CategoryBudgetOverviewCard(totalBudget: 150000, totalSpent: 165000)
        
        CategoryBudgetOverviewCard(title: "Overview", totalBudget: 120000, totalSpent: 115000)
        
        Spacer()
        
    }
    .preferredColorScheme(.dark)
}
