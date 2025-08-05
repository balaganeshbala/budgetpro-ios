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
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            if incomes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.sora(60))
                        .foregroundColor(.gray)
                    
                    Text("No Income Data Available")
                        .font(.sora(18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Add income entries to view your savings analysis.")
                        .font(.sora(14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        SectionHeader(text: "Savings Analysis")
                        
                        SavingsSummaryCard(
                            totalIncome: totalIncome,
                            effectiveExpenses: effectiveExpenses,
                            savings: savings,
                            savingsRate: savingsRate
                        )
                        
                        SavingsRateIndicator(savingsRate: savingsRate)
                        
                        SavingsRecommendations(
                            savingsRate: savingsRate,
                            totalExpenses: totalExpenses,
                            totalBudget: totalBudget
                        )
                    }
                    .padding(16)
                }
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
                .font(.sora(20, weight: .bold))
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
        VStack(spacing: 12) {
            // First row: Net Savings and Savings Rate
            HStack(spacing: 12) {
                ModernSummaryItem(
                    title: "Net Savings",
                    value: CommonHelpers.formatCurrencyWithSign(savings, showSign: false),
                    color: savings >= 0 ? Color(red: 0.259, green: 0.561, blue: 0.490) : .red,
                    icon: savings >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    isPositive: savings >= 0
                )
                
                ModernSummaryItem(
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", savingsRate),
                    color: CommonHelpers.getSavingsRateColor(savingsRate),
                    icon: "percent",
                    isPositive: savingsRate >= 0
                )
            }
            
            // Second row: Income and Expenses
            HStack(spacing: 12) {
                ModernSummaryItem(
                    title: "Income",
                    value: CommonHelpers.formatCurrency(totalIncome),
                    color: Color(red: 0.259, green: 0.561, blue: 0.490),
                    icon: "plus.circle.fill",
                    isPositive: true
                )
                
                ModernSummaryItem(
                    title: "Expenses",
                    value: CommonHelpers.formatCurrency(effectiveExpenses),
                    color: Color(red: 1.0, green: 0.420, blue: 0.420),
                    icon: "minus.circle.fill",
                    isPositive: false
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.02)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
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
                .font(.sora(16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sora(11, weight: .medium))
                    .foregroundColor(Color.gray)
                
                Text(value)
                    .font(.sora(14, weight: .bold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
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
        VStack(spacing: 12) {
            // Icon with background
            Image(systemName: icon)
                .font(.sora(20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.sora(12, weight: .medium))
                    .foregroundColor(Color.gray)
                
                Text(value)
                    .font(.sora(16, weight: .bold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 2, x: 0, y: 1)
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
                    .font(.sora(14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.sora(14))
                    .foregroundColor(.gray)
            }
            
            Text(prefix + value)
                .font(.sora(16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Savings Rate Indicator  
struct SavingsRateIndicator: View {
    let savingsRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Savings Rate")
                    .font(.sora(16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("Financial experts recommend saving at least 20% of your income.")
                    .lineSpacing(4)
                    .font(.sora(14))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Text(String(format: "%.1f%%", savingsRate))
                        .font(.sora(13, weight: .bold))
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
                        .font(.sora(12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("20%")
                        .font(.sora(12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("40%")
                        .font(.sora(12))
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
                
                // Savings rate message container
                HStack(spacing: 12) {
                    Image(systemName: CommonHelpers.getSavingsRateIcon(savingsRate))
                        .foregroundColor(CommonHelpers.getSavingsRateColor(savingsRate))
                        .font(.sora(16))
                    
                    Text(CommonHelpers.getSavingsRateMessage(savingsRate))
                        .font(.sora(14))
                        .foregroundColor(CommonHelpers.getSavingsRateColor(savingsRate))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(CommonHelpers.getSavingsRateColor(savingsRate).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    private func getProgressWidth(_ rate: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 64 // Account for padding
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.sora(16, weight: .semibold))
                .foregroundColor(.black)
            
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
                    .font(.sora(20))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.sora(14))
                    .foregroundColor(.gray)
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
        SavingsAnalysisScreen(
            expenses: sampleExpenses,
            incomes: sampleIncomes,
            totalBudget: 50000,
            month: "Jan",
            year: "2024"
        )
    }
    
    // Sample data for preview
    static let sampleExpenses: [Expense] = [
        Expense(
            id: 1,
            name: "Groceries",
            amount: 5000,
            category: "groceries",
            date: Date(),
            categoryIcon: "cart.fill",
            categoryColor: .mint
        ),
        Expense(
            id: 2,
            name: "Fuel",
            amount: 4000,
            category: "travel",
            date: Date(),
            categoryIcon: "car.fill",
            categoryColor: .blue
        ),
        Expense(
            id: 3,
            name: "Movie Tickets",
            amount: 50000,
            category: "entertainment",
            date: Date(),
            categoryIcon: "tv",
            categoryColor: .indigo
        )
    ]
    
    static let sampleIncomes: [Income] = [
        Income(
            id: 1,
            source: "Salary",
            amount: 60000,
            category: "salary",
            date: Date(),
            categoryIcon: "briefcase.fill"
        ),
        Income(
            id: 2,
            source: "Freelance",
            amount: 15000,
            category: "sideHustle",
            date: Date(),
            categoryIcon: "laptopcomputer"
        )
    ]
}
