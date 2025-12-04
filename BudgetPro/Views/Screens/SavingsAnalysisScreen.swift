//
//  SavingsAnalysisScreen.swift
//  BudgetPro
//
//  Created by Balaganesh S on 05/08/25.
//

import SwiftUI

struct SavingsAnalysisScreen: View {
    let expenses: [Expense]
    let incomes: [Income]
    let totalBudget: Double
    let month: String
    let year: String
    
    // Computed properties for calculations
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var effectiveExpenses: Double {
        CommonHelpers.getEffectiveExpenses(totalExpenses: totalExpenses, 
                                         totalBudget: totalBudget, 
                                         isCurrentMonth: CommonHelpers.isCurrentMonth(month, year))
    }
    
    private var savings: Double {
        totalIncome - effectiveExpenses
    }
    
    private var savingsRate: Double {
        totalIncome > 0 ? (savings / totalIncome) * 100 : 0
    }
    
    var body: some View {
        ZStack {
            
            Color.groupedBackground
                .ignoresSafeArea(.all)
            
            if incomes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.appFont(60))
                        .foregroundColor(.secondaryText)
                    
                    Text("No Income Data Available")
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("Add income entries to view your savings analysis.")
                        .font(.appFont(14))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        SavingsSummaryCard(
                            totalIncome: totalIncome,
                            effectiveExpenses: effectiveExpenses,
                            savings: savings,
                            savingsRate: savingsRate
                        )
                        
                        CardView {
                            ExpenseIncomeBarChart(
                                totalExpenses: effectiveExpenses,
                                totalIncome: totalIncome
                            )
                        }
                        
                        SavingsRateIndicator(savingsRate: savingsRate)
                        
                        SavingsRecommendations(
                            savingsRate: savingsRate,
                            totalExpenses: totalExpenses,
                            totalBudget: totalBudget
                        )
                    }
                    .padding(16)
                }
                .disableScrollViewBounce()
            }
        }
        .navigationTitle("\(month) \(year)")
        .navigationBarTitleDisplayMode(.inline)
    }

}

// MARK: - Section Header
struct SectionHeader: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.appFont(20, weight: .bold))
                .foregroundColor(.primaryText)
            Spacer()
        }
    }
}

// MARK: - Redesigned Savings Summary Card
struct SavingsSummaryCard: View {
    let totalIncome: Double
    let effectiveExpenses: Double
    let savings: Double
    let savingsRate: Double
    
    var body: some View {
        CardView {
            VStack(spacing: 20) {
                HStack {
                    Text("Savings Analysis")
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
                
                ModernSummaryItem(
                    title: "Net Savings",
                    value: CommonHelpers.formatCurrencyWithSign(savings),
                    color: savings >= 0 ? .adaptiveGreen : .adaptiveRed,
                    icon: "suitcase",
                    isPositive: savings >= 0
                )
                
                ModernSummaryItem(
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", savingsRate),
                    color: CommonHelpers.getSavingsRateColor(savingsRate),
                    icon: "percent",
                    isPositive: savingsRate >= 0
                )

                ModernSummaryItem(
                    title: "Income",
                    value: CommonHelpers.formatCurrency(totalIncome),
                    color: .primaryText,
                    icon: "plus.circle",
                    isPositive: true
                )
                
                ModernSummaryItem(
                    title: "Expenses",
                    value: CommonHelpers.formatCurrency(effectiveExpenses),
                    color: .primaryText,
                    icon: "minus.circle",
                    isPositive: false
                )
            }
        }
    }
}

// MARK: - Compact Metric Card
struct CompactMetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.appFont(16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appFont(11, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.appFont(14, weight: .bold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .shadow(color: color.opacity(0.08), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Modern Summary Item
struct ModernSummaryItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            RowItemIcon(categoryIcon: icon, iconShape: .circle)
        
            Text(title)
                .font(.appFont(14, weight: .regular))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.appFont(16, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary Item (Legacy - keeping for compatibility)
struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let prefix: String
    
    init(title: String, value: String, color: Color, icon: String, prefix: String = "") {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.prefix = prefix
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.appFont(14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
            }
            
            Text(prefix + value)
                .font(.appFont(16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Savings Rate Indicator  
struct SavingsRateIndicator: View {
    let savingsRate: Double
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Savings Rate")
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("Financial experts recommend saving at least 20% of your income.")
                        .lineSpacing(4)
                        .font(.appFont(14))
                        .foregroundColor(.secondaryText)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text(String(format: "%.1f%%", savingsRate))
                            .font(.appFont(13, weight: .bold))
                            .foregroundColor(CommonHelpers.getSavingsRateColor(savingsRate))
                    }
                    
                    ZStack {
                        // Background bar
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 24)
                            .cornerRadius(12)
                        
                        // Progress bar
                        HStack {
                            Rectangle()
                                .fill(CommonHelpers.getSavingsRateColor(savingsRate))
                                .frame(width: max(getProgressWidth(savingsRate), 0), height: 24)
                                .cornerRadius(12)
                                .animation(.easeInOut(duration: 0.5), value: savingsRate)
                            Spacer(minLength: 0)
                        }
                        
                        // Markers overlay
                        HStack {
                            Spacer(minLength: 1)
                            buildMarker(10, savingsRate)
                            Spacer()
                            buildMarker(20, savingsRate)
                            Spacer()
                            buildMarker(30, savingsRate)
                            Spacer(minLength: 1)
                        }
                        .frame(height: 24)
                    }
                    
                    // Labels below progress bar
                    HStack {
                        Text("0%")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text("20%")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text("40%")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.top, 8)
                    
                    // Savings rate message container
                    HStack(spacing: 12) {
                        Image(systemName: CommonHelpers.getSavingsRateIcon(savingsRate))
                            .foregroundColor(.secondary)
                            .font(.appFont(16))
                        
                        Text(CommonHelpers.getSavingsRateMessage(savingsRate))
                            .font(.appFont(14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(Color.groupedBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func getProgressWidth(_ rate: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 56 // Account for padding
        let maxRate: Double = 40 // Cap at 40% for visual purposes
        let clampedRate = min(rate, maxRate)
        return CGFloat(clampedRate / maxRate) * screenWidth
    }
    
    private func buildMarker(_ percentage: Double, _ currentRate: Double) -> some View {
        Circle()
            .fill(currentRate >= percentage ? Color.white : Color.gray.opacity(0.5))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(currentRate >= percentage ? CommonHelpers.getSavingsRateColor(currentRate) : Color.gray, lineWidth: 2)
            )
    }
}

// MARK: - Savings Recommendations
struct SavingsRecommendations: View {
    let savingsRate: Double
    let totalExpenses: Double
    let totalBudget: Double
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recommendations")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 16) {
                    ForEach(getRecommendations(), id: \.title) { recommendation in
                        RecommendationItem(
                            title: recommendation.title,
                            description: recommendation.description,
                            icon: recommendation.icon,
                            color: recommendation.color
                        )
                    }
                }
            }
        }
    }
    
    private func getRecommendations() -> [(title: String, description: String, icon: String, color: Color)] {
        return CommonHelpers.getSavingsRecommendations(
            savingsRate: savingsRate,
            totalExpenses: totalExpenses,
            totalBudget: totalBudget
        )
    }
}

// MARK: - Recommendation Item
struct RecommendationItem: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Image(systemName: icon)
                    .font(.appFont(20))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.appFont(14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct SavingsAnalysisScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SavingsAnalysisScreen(
                    expenses: sampleExpenses,
                    incomes: sampleIncomes,
                    totalBudget: 50000,
                    month: "Jan",
                    year: "2024"
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            NavigationView {
                SavingsAnalysisScreen(
                    expenses: sampleExpenses,
                    incomes: sampleIncomes,
                    totalBudget: 50000,
                    month: "Jan",
                    year: "2024"
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
    
    // Sample data for preview
    static let sampleExpenses: [Expense] = [
        Expense(
            id: 1,
            name: "Groceries",
            amount: 20000,
            category: .groceries,
            date: Date()
        ),
        Expense(
            id: 2,
            name: "Fuel",
            amount: 40000,
            category: .travel,
            date: Date()
        ),
        Expense(
            id: 3,
            name: "Movie Tickets",
            amount: 4000,
            category: .entertainment,
            date: Date()
        )
    ]
    
    static let sampleIncomes: [Income] = [
        Income(
            id: 1,
            source: "Salary",
            amount: 60000,
            category: .salary,
            date: Date()
        ),
        Income(
            id: 2,
            source: "Freelance",
            amount: 15000,
            category: .sideHustle,
            date: Date()
        )
    ]
}

