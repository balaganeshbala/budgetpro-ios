//
//  BudgetOverviewCard.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/10/25.
//

import SwiftUI

// MARK: - Budget Overview Card Component

struct BudgetOverviewCard: View {
    let title: String?
    let totalBudget: Double
    let totalSpent: Double
    let showEditButton: Bool
    let showDetailsButton: Bool
    let onEditTapped: (() -> Void)?
    let onDetailsTapped: (() -> Void)?
    
    // Expansion state for Budget Summary Row
    @State private var isSummaryExpanded: Bool = false
    
    init(
        title: String? = nil,
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
    
    private var usageBasedColor: Color {
        isOverBudget ? .adaptiveRed : usagePercentage > 80 ? .warningColor : .adaptiveGreen
    }
    
    private var spentBasedColor: Color {
        isOverBudget ? .adaptiveRed : .primaryText
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            if title != nil || showEditButton {
                HStack {
                    if let title = title {
                        Text(title)
                            .font(.appFont(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    if showEditButton {
                        Button(action: {
                            onEditTapped?()
                        }) {
                            Label {
                                Text("Edit")
                                    .font(.appFont(14, weight: .semibold))
                            } icon: {
                                if #available(iOS 16.0, *) {
                                    Image(systemName: "pencil")
                                        .fontWeight(.bold)
                                } else {
                                    Image(systemName: "pencil")
                                }
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                }
            }
            
            // Budget content
            VStack(spacing: 20) {
                // Remaining Amount - Highlighted at the top
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSummaryExpanded.toggle()
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Group {
                                    Text(isOverBudget ? "Overspent": "Remaining Budget")
                                        .font(.appFont(18, weight: .medium))
                                        .foregroundColor(.secondaryText)
                                    
                                    Text("₹\(CommonHelpers.formatAmount(abs(remainingBudget)))")
                                        .font(.appFont(30, weight: .bold))
                                        .foregroundStyle(spentBasedColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Chevron on right side
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondaryText)
                                .rotationEffect(.degrees(isSummaryExpanded ? 90 : 0))
                                .animation(.easeInOut(duration: 0.25), value: isSummaryExpanded)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                    
                    Divider()
                    
                    // Budget Summary Row (Expandable/Collapsible)
                    if isSummaryExpanded {
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
                
                // Details Button
                if showDetailsButton {
                    Button(action: {
                        onDetailsTapped?()
                    }) {
                        HStack {
                            Text("View Budget Details")
                                .font(.appFont(14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
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

#Preview {
    VStack {
        BudgetOverviewCard(totalBudget: 150000, totalSpent: 165000, showEditButton: false, showDetailsButton: false) {
            
        } onDetailsTapped: {
            
        }
        
        BudgetOverviewCard(title: "Overview", totalBudget: 120000, totalSpent: 95000, showEditButton: true, showDetailsButton: true) {
            
        } onDetailsTapped: {
            
        }
        
        Spacer()
        
    }
}

#Preview {
    VStack {
        BudgetOverviewCard(totalBudget: 150000, totalSpent: 165000, showEditButton: false, showDetailsButton: false) {
            
        } onDetailsTapped: {
            
        }
        
        BudgetOverviewCard(title: "Overview", totalBudget: 120000, totalSpent: 115000, showEditButton: true, showDetailsButton: true) {
            
        } onDetailsTapped: {
            
        }
        
        Spacer()
        
    }
    .preferredColorScheme(.dark)
}
