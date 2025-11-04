//
//  AllMajorExpensesView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import SwiftUI

// MARK: - All Major Expenses View
struct AllMajorExpensesView: View {
    @EnvironmentObject private var coordinator: MainCoordinator
    @StateObject private var viewModel: AllMajorExpensesViewModel
    
    init(repoService: DataFetchRepoService) {
        self._viewModel = StateObject(wrappedValue: AllMajorExpensesViewModel(repoService: repoService))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.majorExpenses.isEmpty {
                    loadingView
                } else if viewModel.majorExpenses.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    // Major Expense Summary Section
                    MajorExpenseSummaryView(majorExpenses: viewModel.majorExpenses)
                    
                    // Sort Section
                    sortSection
                    
                    // Major Expenses List
                    majorExpensesListSection
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.groupedBackground)
        .navigationTitle("Major Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    coordinator.navigate(to: .addMajorExpense)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .onAppear {
            Task {
                await viewModel.loadMajorExpenses()
            }
        }
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        LoadingView(titleText: "Loading major expenses...")
            .padding(.top, 100)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            VStack(spacing: 8) {
                Text("No Major Expenses")
                    .font(.appFont(20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Start tracking your major expenses by adding your first one.")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                coordinator.navigate(to: .addMajorExpense)
            }) {
                Text("Add Major Expense")
                    .font(.appFont(16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("All Major Expenses")
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
    
    // MARK: - Major Expenses List Section
    private var majorExpensesListSection: some View {
        CardView(padding: EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.sortedMajorExpenses.enumerated()), id: \.offset) { index, majorExpense in
                    TransactionRow<MajorExpense, MajorExpenseDetailsView>(
                        title: majorExpense.name,
                        amount: majorExpense.amount,
                        dateString: majorExpense.dateString,
                        categoryIcon: majorExpense.category.iconName,
                        categoryColor: majorExpense.category.color,
                        iconShape: .roundedRectangle,
                        amountColor: .primaryText,
                        showChevron: true,
                        destination: {
                            MajorExpenseDetailsView(majorExpense: majorExpense, repoService: coordinator.majorExpenseRepo)
                        }
                    )
                    
                    if index < viewModel.sortedMajorExpenses.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Major Expense Summary View
struct MajorExpenseSummaryView: View {
    let majorExpenses: [MajorExpense]
    
    private var totalMajorExpense: Double {
        majorExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categoryTotals: [String: Double] {
        var totals: [String: Double] = [:]
        for expense in majorExpenses {
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
                // Total Major Expense Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Major Expenses")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        Spacer()
                    }
                    
                    HStack {
                        Text("₹\(formatAmount(totalMajorExpense))")
                            .font(.appFont(24, weight: .bold))
                            .foregroundColor(Color.primaryText)
                        Spacer()
                    }
                }
                
                if !sortedCategories.isEmpty {
                    Divider()
                    
                    // Category Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Major Expenses by Category")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(sortedCategories, id: \.category) { categoryData in
                                MajorCategoryBreakdownRow(
                                    category: categoryData.category,
                                    amount: categoryData.amount,
                                    percentage: totalMajorExpense > 0 ? (categoryData.amount / totalMajorExpense) * 100 : 0
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

// MARK: - Major Category Breakdown Row
struct MajorCategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    
    private var categoryColor: Color {
        return MajorExpenseCategory.from(categoryName: category).color
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
struct AllMajorExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AllMajorExpensesView(repoService: SupabaseDataFetchRepoService())
        }
    }
}
