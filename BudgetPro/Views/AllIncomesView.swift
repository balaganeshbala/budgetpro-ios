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
                
                // Incomes List
                incomesListSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.gray.opacity(0.1))
        .navigationTitle(monthYearTitle)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Set navigation bar to white/system background
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("All Incomes")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
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
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                }
            }
            
            HStack {
                Text("Sorted by: ")
                    .font(.sora(14))
                    .foregroundColor(.gray)
                
                Text(viewModel.currentSortType.rawValue)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                
                Spacer()
            }
        }
    }
    
    // MARK: - Incomes List Section
    private var incomesListSection: some View {
        VStack(spacing: 0) {
            if viewModel.sortedIncomes.isEmpty {
                EmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No incomes yet",
                    subtitle: "Add your income sources to track earnings",
                    buttonTitle: "Add Income",
                    action: {
                        // Navigate to add income
                    }
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.sortedIncomes.enumerated()), id: \.offset) { index, income in
                        TransactionRow<Income, IncomeDetailsView>(
                            title: income.source,
                            amount: income.amount,
                            dateString: income.dateString,
                            categoryIcon: income.categoryIcon,
                            categoryColor: IncomeCategory.from(categoryName: income.category).color,
                            iconShape: .roundedRectangle,
                            amountColor: .black,
                            showChevron: true,
                            destination: {
                                IncomeDetailsView(income: income)
                            }
                        )
                        
                        if index < viewModel.sortedIncomes.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    private var monthYearTitle: String {
        let monthNames = ["", "January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
        return "\(monthNames[month]) \(year)"
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
            totals[income.category, default: 0] += income.amount
        }
        return totals
    }
    
    private var sortedCategories: [(category: String, amount: Double)] {
        categoryTotals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Total Income Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Income")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack {
                    Text("₹\(formatAmount(totalIncome))")
                        .font(.sora(24, weight: .bold))
                        .foregroundColor(Color.primary)
                    Spacer()
                }
            }
            
            if !sortedCategories.isEmpty {
                Divider()
                
                // Category Breakdown Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Income by Category")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
                .foregroundColor(.black)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(formatAmount(amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.sora(12))
                    .foregroundColor(.gray)
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
    static var previews: some View {
        AllIncomesView(
            incomes: [
                Income(
                    id: 1,
                    source: "Monthly Salary",
                    amount: 50000,
                    category: "salary",
                    date: Date(),
                    categoryIcon: "briefcase.fill"
                ),
                Income(
                    id: 2,
                    source: "Freelance Project",
                    amount: 15000,
                    category: "sideHustle",
                    date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                    categoryIcon: "laptopcomputer"
                ),
                Income(
                    id: 3,
                    source: "Investment Returns",
                    amount: 5000,
                    category: "investment",
                    date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                    categoryIcon: "chart.line.uptrend.xyaxis"
                )
            ],
            month: 8,
            year: 2025
        )
    }
}