//
//  BudgetOverviewCard.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/10/25.
//

import SwiftUI

// MARK: - Budget Overview Card Component

struct BudgetOverviewCard: View {
    let title: String
    let totalBudget: Double
    let totalSpent: Double
    let showEditButton: Bool
    let showDetailsButton: Bool
    let onEditTapped: (() -> Void)?
    let onDetailsTapped: (() -> Void)?
    
    init(
        title: String = "Budget Overview",
        totalBudget: Double,
        totalSpent: Double,
        showEditButton: Bool = false,
        showDetailsButton: Bool = false,
        onEditTapped: (() -> Void)? = nil,
        onDetailsTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.totalBudget = totalBudget
        self.totalSpent = totalSpent
        self.showEditButton = showEditButton
        self.showDetailsButton = showDetailsButton
        self.onEditTapped = onEditTapped
        self.onDetailsTapped = onDetailsTapped
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if showEditButton {
                    Button(action: {
                        onEditTapped?()
                    }) {
                        Label {
                            Text("Edit")
                                .font(.sora(14, weight: .semibold))
                        } icon: {
                            if #available(iOS 16.0, *) {
                                Image(systemName: "pencil")
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "pencil")
                            }
                        }
                        .foregroundColor(.adaptiveSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.adaptiveSecondary.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
            }
            
            // Budget content
            VStack(spacing: 20) {
                // Remaining Amount - Highlighted at the top
                VStack(alignment: .center, spacing: 8) {
                    Text(isOverBudget ? "Overspent": "Remaining Budget")
                        .font(.sora(18, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text("₹\(CommonHelpers.formatAmount(abs(remainingBudget)))")
                        .font(.sora(30, weight: .bold))
                        .foregroundColor(isOverBudget ? .overBudgetColor : .adaptivePrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isOverBudget ? Color.overBudgetColor.opacity(0.05) : Color.adaptivePrimary.opacity(0.05),
                            isOverBudget ? Color.overBudgetColor.opacity(0.1) : Color.adaptivePrimary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isOverBudget ? Color.overBudgetColor.opacity(0.2) : Color.adaptivePrimary.opacity(0.2), lineWidth: 1)
                )
                
                // Budget Summary Row
                HStack(spacing: 16) {
                    // Total Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.sora(14))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(CommonHelpers.formatAmount(totalBudget))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Total Spent
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Spent")
                            .font(.sora(14))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(CommonHelpers.formatAmount(totalSpent))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(isOverBudget ? .overBudgetColor : .warningColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Progress Bar with Percentage
                if totalBudget > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Budget Usage")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Text("\(usagePercentage)%")
                                .font(.sora(16, weight: .bold))
                                .foregroundColor(isOverBudget ? .overBudgetColor : .warningColor)
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
                                                isOverBudget ? Color.overBudgetColor : Color.warningColor,
                                                isOverBudget ? Color.overBudgetColor.opacity(0.8) : Color.warningColor.opacity(0.8)
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
                
                // Details Button
                if showDetailsButton {
                    Button(action: {
                        onDetailsTapped?()
                    }) {
                        HStack {
                            Text("View Budget Details")
                                .font(.sora(14, weight: .semibold))
                                .foregroundColor(.adaptiveSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.adaptiveSecondary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 4)
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
