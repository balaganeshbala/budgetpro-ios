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
    
    let budgetCategories: [BudgetCategory]
    let totalBudget: Double
    let expenses: [Expense]
    let month: Int
    let year: Int
    
    init(budgetCategories: [BudgetCategory], totalBudget: Double, expenses: [Expense], month: Int, year: Int) {
        self.budgetCategories = budgetCategories
        self.totalBudget = totalBudget
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
                
                // Expenses by categories
                categoriesSection
                
                // Sort Section
                sortSection
                
                // All expenses List
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
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Expense by Category")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(sortedCategories) { category in
                    Button(action: {
                        coordinator.navigate(to: .categoryDetail(category: category, expenses: expenses, month: month, year: year))
                    }) {
                        BudgetCategoryCard(category: category, totalBudget: totalBudget)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
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

extension AllExpensesView {
    private var sortedCategories: [BudgetCategory] {
        // Filter out unknown categories
        let validCategories = budgetCategories.filter { category in
            ExpenseCategory.from(categoryName: category.name) != .unknown
        }
        
        let unplannedCategories = validCategories.filter { $0.budget == 0 && $0.spent > 0 }
        let noBudgetCategories = validCategories.filter { $0.budget == 0 && $0.spent == 0 }
        let plannedCategories = validCategories.filter { $0.budget > 0 }
        
        let sortedPlanned = plannedCategories.sorted { first, second in
            let firstPercentage = first.spent / first.budget
            let secondPercentage = second.spent / second.budget
            return firstPercentage > secondPercentage
        }
        
        return unplannedCategories + sortedPlanned + noBudgetCategories
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
                        Text("₹\(CommonHelpers.formatAmount(totalExpense))")
                            .font(.appFont(24, weight: .bold))
                            .foregroundColor(Color.primaryText)
                        Spacer()
                    }
                }
            }
        }
    }
}


// MARK: - Preview
struct AllExpensesView_Previews: PreviewProvider {
    
    @StateObject static var coordinator = MainCoordinator(userId: "userId")
    
    static var sampleBudgetCategories: [BudgetCategory] {
        [
            BudgetCategory(id: "1", name: "Food", budget: 4000, spent: 3500),
            BudgetCategory(id: "2", name: "Travel", budget: 2000, spent: 800),
            BudgetCategory(id: "3", name: "Entertainment", budget: 1500, spent: 600)
        ]
    }
    
    static var sampleTotalBudget: Double {
        sampleBudgetCategories.reduce(0) { $0 + $1.budget }
    }
    
    static var sampleExpenses: [Expense] {
        [
            Expense(
                id: 1,
                name: "Lunch at Restaurant",
                amount: 850,
                category: .food,
                date: Date(),
                userId: "preview-user"
            ),
            Expense(
                id: 2,
                name: "Metro Card Recharge",
                amount: 500,
                category: .travel,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                userId: "preview-user"
            ),
            Expense(
                id: 3,
                name: "Movie Tickets",
                amount: 600,
                category: .entertainment,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                userId: "preview-user"
            ),
            Expense(
                id: 4,
                name: "Grocery Shopping",
                amount: 2500,
                category: .food,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                userId: "preview-user"
            ),
            Expense(
                id: 5,
                name: "Coffee",
                amount: 150,
                category: .food,
                date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                userId: "preview-user"
            )
        ]
    }
    
    static var previews: some View {
        Group {
            // Light Theme Preview
            NavigationView {
                AllExpensesView(
                    budgetCategories: sampleBudgetCategories,
                    totalBudget: sampleTotalBudget,
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
                    budgetCategories: sampleBudgetCategories,
                    totalBudget: sampleTotalBudget,
                    expenses: sampleExpenses,
                    month: 7,
                    year: 2025
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Theme")
        }
        .environmentObject(coordinator)
    }
}
