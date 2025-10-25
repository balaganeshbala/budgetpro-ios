//
//  AllIncomesView.swift
//  BudgetPro
//
//  Created by Claude on 04/08/25.
//

import SwiftUI

// MARK: - All Incomes View
struct AllIncomesView: View {
    @StateObject private var viewModel: AllIncomesViewModel
    
    @EnvironmentObject private var coordinator: MainCoordinator
    
    let incomes: [Income]
    let month: Int
    let year: Int
    
    init(incomes: [Income], month: Int, year: Int) {
        self.incomes = incomes
        self.month = month
        self.year = year
        self._viewModel = StateObject(wrappedValue: AllIncomesViewModel(incomes: incomes))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Income Summary Section
                IncomeSummaryView(incomes: incomes)
                
                // Sort Section
                sortSection
                
                // All Incomes List
                allIncomesListSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .disableScrollViewBounce()
        .background(Color.groupedBackground)
        .navigationTitle(monthYearTitle(month: month, year: year))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("All Incomes")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Menu {
                    ForEach(SortType.allCases, id: \.self) { sortType in
                        Button(action: {
                            viewModel.setSortType(sortType)
                        }) {
                            HStack {
                                Text(sortType.rawValue)
                                if viewModel.currentSortType == sortType {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Sorted by: ")
                    .font(.sora(14))
                    .foregroundColor(.secondaryText)
                
                Text(viewModel.currentSortType.rawValue)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - All Incomes List Section
    private var allIncomesListSection: some View {
        VStack(spacing: 12) {
            // All Incomes List
            CardView(padding: EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.sortedIncomes.enumerated()), id: \.offset) { index, income in
                        TransactionRow<Income, IncomeDetailsView>(
                            title: income.source,
                            amount: income.amount,
                            dateString: income.dateString,
                            categoryIcon: income.category.iconName,
                            categoryColor: income.category.color,
                            iconShape: .roundedRectangle,
                            amountColor: .primaryText,
                            showChevron: true,
                            destination: {
                                IncomeDetailsView(income: income, repoSerice: coordinator.incomeRepo)
                            }
                        )
                        
                        if index < viewModel.sortedIncomes.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - All Incomes View Model
@MainActor
class AllIncomesViewModel: ObservableObject {
    @Published var sortedIncomes: [Income] = []
    @Published var currentSortType: SortType = .dateNewest
    
    private let originalIncomes: [Income]
    
    init(incomes: [Income]) {
        self.originalIncomes = incomes
        self.sortedIncomes = incomes
        sortIncomes()
    }
    
    func setSortType(_ sortType: SortType) {
        currentSortType = sortType
        sortIncomes()
    }
    
    private func sortIncomes() {
        switch currentSortType {
        case .dateNewest:
            sortedIncomes = originalIncomes.sorted { $0.date > $1.date }
        case .dateOldest:
            sortedIncomes = originalIncomes.sorted { $0.date < $1.date }
        case .amountHighest:
            sortedIncomes = originalIncomes.sorted { $0.amount > $1.amount }
        case .amountLowest:
            sortedIncomes = originalIncomes.sorted { $0.amount < $1.amount }
        }
    }
}

// MARK: - Income Summary View
struct IncomeSummaryView: View {
    let incomes: [Income]
    
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    private var categoryTotals: [String: Double] {
        var totals: [String: Double] = [:]
        for income in incomes {
            totals[income.category.displayName, default: 0] += income.amount
        }
        return totals
    }
    
    private var sortedCategories: [(category: String, amount: Double)] {
        categoryTotals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Income Type Summary Section
    private var incomeTypeSummarySection: some View {
        let primaryIncomes = incomes.filter { $0.category == .salary }
        let secondaryIncomes = incomes.filter { $0.category != .salary }
        let totalPrimary = primaryIncomes.reduce(0) { $0 + $1.amount }
        let totalSecondary = secondaryIncomes.reduce(0) { $0 + $1.amount }
        
        return VStack(spacing: 16) {
            
            Divider()
            
            HStack(spacing: 12) {
                ModernSummaryItem(
                    title: "Primary",
                    value: CommonHelpers.formatCurrency(totalPrimary),
                    color: .green,
                    icon: "plus.circle.fill",
                    isPositive: true
                )
                
                ModernSummaryItem(
                    title: "Secondary",
                    value: CommonHelpers.formatCurrency(totalSecondary),
                    color: .orange,
                    icon: "star.circle.fill",
                    isPositive: false
                )
            }
        }
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                // Total Income Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Income")
                            .font(.sora(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        Spacer()
                    }
                    
                    HStack {
                        Text("₹\(formatAmount(totalIncome))")
                            .font(.sora(24, weight: .bold))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                }
                
                incomeTypeSummarySection
                
                if !sortedCategories.isEmpty {
                    Divider()
                    
                    // Category Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Income by Category")
                            .font(.sora(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(sortedCategories.prefix(5), id: \.category) { categoryData in
                                IncomeCategoryBreakdownRow(
                                    category: categoryData.category,
                                    amount: categoryData.amount,
                                    percentage: totalIncome > 0 ? (categoryData.amount / totalIncome) * 100 : 0
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Income Category Breakdown Row
struct IncomeCategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    
    private var categoryColor: Color {
        return IncomeCategory.from(categoryName: category).color
    }
    
    var body: some View {
        HStack {
            // Category indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)
            
            Text(IncomeCategory.from(categoryName: category).displayName)
                .font(.sora(14, weight: .medium))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(formatAmount(amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.sora(12))
                    .foregroundColor(.secondaryText)
            }
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Preview
struct AllIncomesView_Previews: PreviewProvider {
    static var sampleIncomes: [Income] {
        [
            Income(
                id: 1,
                source: "Monthly Salary",
                amount: 50000,
                category: .salary,
                date: Date()
            ),
            Income(
                id: 2,
                source: "Freelance Project",
                amount: 15000,
                category: .sideHustle,
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            Income(
                id: 3,
                source: "Investment Returns",
                amount: 5000,
                category: .investment,
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
            ),
            Income(
                id: 4,
                source: "Rental Income",
                amount: 12000,
                category: .investment,
                date: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date()
            ),
            Income(
                id: 5,
                source: "Bonus",
                amount: 8000,
                category: .salary,
                date: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date()
            )
        ]
    }
    
    static var previews: some View {
        Group {
            // Light Theme Preview
            NavigationView {
                AllIncomesView(
                    incomes: sampleIncomes,
                    month: 8,
                    year: 2025
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Theme")
            
            // Dark Theme Preview
            NavigationView {
                AllIncomesView(
                    incomes: sampleIncomes,
                    month: 8,
                    year: 2025
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Theme")
        }
    }
}
