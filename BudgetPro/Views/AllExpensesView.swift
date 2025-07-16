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
    @StateObject private var viewModel: AllExpensesViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
        NavigationView {
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
            .background(Color.gray.opacity(0.1))
            .navigationTitle(monthYearTitle)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.sora(16))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
            )
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("All Expenses")
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
    
    // MARK: - Expenses List Section
    private var expensesListSection: some View {
        VStack(spacing: 0) {
            if viewModel.sortedExpenses.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "No expenses yet",
                    subtitle: "Add your first expense to track spending",
                    buttonTitle: "Add Expense",
                    action: {
                        // Navigate to add expense
                    }
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.sortedExpenses.enumerated()), id: \.offset) { index, expense in
                        ExpenseListRow(
                            expense: expense,
                            onTap: {
                                viewModel.navigateToExpenseDetails(expense)
                            }
                        )
                        
                        if index < viewModel.sortedExpenses.count - 1 {
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

// MARK: - All Expenses View Model
@MainActor
class AllExpensesViewModel: ObservableObject {
    @Published var sortedExpenses: [Expense] = []
    @Published var currentSortType: SortType = .dateNewest
    @Published var shouldDismiss = false
    
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
    
    func navigateToExpenseDetails(_ expense: Expense) {
        // This would navigate to expense details
        // Implementation depends on your navigation approach
        print("Navigate to expense details: \(expense.name)")
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
            totals[expense.category, default: 0] += expense.amount
        }
        return totals
    }
    
    private var sortedCategories: [(category: String, amount: Double)] {
            categoryTotals.map { (category: $0.key, amount: $0.value) }
                .sorted { $0.amount > $1.amount }
        }
    
    var body: some View {
        VStack(spacing: 16) {
            // Total Expense Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Expenses")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack {
                    Text("₹\(formatAmount(totalExpense))")
                        .font(.sora(24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    Spacer()
                }
            }
            
            if !sortedCategories.isEmpty {
                Divider()
                
                // Category Breakdown Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expenses by Category")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(sortedCategories.prefix(5), id: \.category) { categoryData in
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

// MARK: - Expense List Row
struct ExpenseListRow: View {
    let expense: Expense
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Circle()
                    .fill(expense.categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: expense.categoryIcon)
                            .foregroundColor(expense.categoryColor)
                            .font(.system(size: 16))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name)
                        .font(.sora(14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(expense.dateString)
                        .font(.sora(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(formatExpenseAmount(expense.amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatExpenseAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.sora(14))
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview
struct AllExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        AllExpensesView(
            expenses: [
                Expense(
                    id: 1,
                    name: "Lunch at Restaurant",
                    amount: 850,
                    category: "Food",
                    date: Date(),
                    categoryIcon: "fork.knife",
                    categoryColor: .orange
                ),
                Expense(
                    id: 2,
                    name: "Metro Card Recharge",
                    amount: 500,
                    category: "Transport",
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    categoryIcon: "car.fill",
                    categoryColor: .blue
                ),
                Expense(
                    id: 3,
                    name: "Movie Tickets",
                    amount: 600,
                    category: "Entertainment",
                    date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                    categoryIcon: "tv",
                    categoryColor: .purple
                )
            ],
            month: 7,
            year: 2025
        )
    }
}
