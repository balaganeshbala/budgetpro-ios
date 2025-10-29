//
//  AllExpensesView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 15/07/25.
//


import SwiftUI

// MARK: - Sort Type Enum
enum SortType: String, CaseIterable {
    case dateNewest = "Date (Newest First)"
    case dateOldest = "Date (Oldest First)"
    case amountHighest = "Amount (Highest First)"
    case amountLowest = "Amount (Lowest First)"
}

// MARK: - All Expenses View
struct AllExpensesView: View {
    
    @EnvironmentObject private var coordinator: MainCoordinator
    
    @StateObject private var viewModel: AllExpensesViewModel
    
    let expenses: [Expense]
    let month: Int
    let year: Int
    
    init(expenses: [Expense], month: Int, year: Int) {
        self.expenses = expenses
        self.month = month
        self.year = year
        self._viewModel = StateObject(wrappedValue: AllExpensesViewModel(expenses: expenses))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Expense Summary Section
                ExpenseSummaryView(expenses: expenses)
                
                // Sort Section
                sortSection
                
                // Expenses List
                expensesListSection
                
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
                Text("All Expenses")
                    .font(.appFont(18, weight: .semibold))
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
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Text("Sorted by: ")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                
                Text(viewModel.currentSortType.rawValue)
                    .font(.appFont(14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Expenses List Section
    private var expensesListSection: some View {
        CardView(padding: EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.sortedExpenses.enumerated()), id: \.offset) { index, expense in
                    TransactionRow<Expense, ExpenseDetailsView>(
                        title: expense.name,
                        amount: expense.amount,
                        dateString: expense.dateString,
                        categoryIcon: expense.category.iconName,
                        categoryColor: expense.category.color,
                        iconShape: .roundedRectangle,
                        amountColor: .primaryText,
                        showChevron: true,
                        destination: {
                            ExpenseDetailsView(expense: expense, repoService: coordinator.expenseRepo)
                        }
                    )
                    
                    if index < viewModel.sortedExpenses.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

// MARK: - All Expenses View Model
@MainActor
class AllExpensesViewModel: ObservableObject {
    @Published var sortedExpenses: [Expense] = []
    @Published var currentSortType: SortType = .dateNewest
    
    private let originalExpenses: [Expense]
    
    init(expenses: [Expense]) {
        self.originalExpenses = expenses
        self.sortedExpenses = expenses
        sortExpenses()
    }
    
    func setSortType(_ sortType: SortType) {
        currentSortType = sortType
        sortExpenses()
    }
    
    
    private func sortExpenses() {
        switch currentSortType {
        case .dateNewest:
            sortedExpenses = originalExpenses.sorted { $0.date > $1.date }
        case .dateOldest:
            sortedExpenses = originalExpenses.sorted { $0.date < $1.date }
        case .amountHighest:
            sortedExpenses = originalExpenses.sorted { $0.amount > $1.amount }
        case .amountLowest:
            sortedExpenses = originalExpenses.sorted { $0.amount < $1.amount }
        }
    }
}

// MARK: - Expense Summary View
struct ExpenseSummaryView: View {
    let expenses: [Expense]
    
    private var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categoryTotals: [String: Double] {
        var totals: [String: Double] = [:]
        for expense in expenses {
            totals[expense.category.displayName, default: 0] += expense.amount
        }
        return totals
    }
    
    private var sortedCategories: [(category: String, amount: Double)] {
            categoryTotals.map { (category: $0.key, amount: $0.value) }
                .sorted { $0.amount > $1.amount }
        }
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                // Total Expense Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Expenses")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        Spacer()
                    }
                    
                    HStack {
                        Text("₹\(formatAmount(totalExpense))")
                            .font(.appFont(24, weight: .bold))
                            .foregroundColor(Color.primaryText)
                        Spacer()
                    }
                }
                
                if !sortedCategories.isEmpty {
                    Divider()
                    
                    // Category Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expenses by Category")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(sortedCategories, id: \.category) { categoryData in
                                CategoryBreakdownRow(
                                    category: categoryData.category,
                                    amount: categoryData.amount,
                                    percentage: totalExpense > 0 ? (categoryData.amount / totalExpense) * 100 : 0
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

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    
    private var categoryColor: Color {
        return ExpenseCategory.from(categoryName: category).color
    }
    
    var body: some View {
        HStack {
            // Category indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)
            
            Text(category)
                .font(.appFont(14, weight: .medium))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(formatAmount(amount))")
                    .font(.appFont(14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.appFont(12))
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
struct AllExpensesView_Previews: PreviewProvider {
    static var sampleExpenses: [Expense] {
        [
            Expense(
                id: 1,
                name: "Lunch at Restaurant",
                amount: 850,
                category: .food,
                date: Date()
            ),
            Expense(
                id: 2,
                name: "Metro Card Recharge",
                amount: 500,
                category: .travel,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            Expense(
                id: 3,
                name: "Movie Tickets",
                amount: 600,
                category: .entertainment,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            Expense(
                id: 4,
                name: "Grocery Shopping",
                amount: 2500,
                category: .food,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            Expense(
                id: 5,
                name: "Coffee",
                amount: 150,
                category: .food,
                date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            )
        ]
    }
    
    static var previews: some View {
        Group {
            // Light Theme Preview
            NavigationView {
                AllExpensesView(
                    expenses: sampleExpenses,
                    month: 7,
                    year: 2025
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Theme")
            
            // Dark Theme Preview
            NavigationView {
                AllExpensesView(
                    expenses: sampleExpenses,
                    month: 7,
                    year: 2025
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Theme")
        }
    }
}
