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
        VStack(spacing: 0) {
            // Fixed Year Picker Header
            yearPickerHeader
            
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
            }
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
        VStack(spacing: 16) {
            
            EmptyDataIndicatorView(icon: "creditcard.trianglebadge.exclamationmark",
                                   title: "No Major Expenses",
                                   bodyText: "Start tracking your major expenses by adding your first one")
            
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
    
    // MARK: - Year Picker Header
    private var yearPickerHeader: some View {
        HStack {
            Spacer()
            
            Menu {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    Button(action: {
                        viewModel.selectedYear = year
                    }) {
                        HStack {
                            Text(String(year))
                            if viewModel.selectedYear == year {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(String(viewModel.selectedYear))
                        .font(.appFont(14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.cardBackground)
                .cornerRadius(8)
                .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onChange(of: viewModel.selectedYear) { _ in
            Task {
                await viewModel.loadMajorExpenses()
            }
        }
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("All Major Expenses")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Sort Menu
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
                        Text("₹\(CommonHelpers.formatAmount(totalMajorExpense))")
                            .font(.appFont(20, weight: .bold))
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
                Text("₹\(CommonHelpers.formatAmount(amount))")
                    .font(.appFont(14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.appFont(12))
                    .foregroundColor(.secondaryText)
            }
        }
    }
}

// MARK: - Preview
struct AllMajorExpensesView_Previews: PreviewProvider {
    
    // Simple mock
    private final class MockDataFetchRepoService: DataFetchRepoService {
        
        let shouldReturnEmptyData: Bool
        
        init(shouldReturnEmptyData: Bool = false) {
            self.shouldReturnEmptyData = shouldReturnEmptyData
        }
        
        func fetchAll<T>(from table: String, filters: [RepoQueryFilter], orderBy: String?) async throws -> [T] where T : Decodable {
            
            if shouldReturnEmptyData {
                return []
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            let previewUserId = "preview-user"
            
            if T.self == MajorExpense.self, table == "major_expenses" {
                let result: [MajorExpense] = [
                    MajorExpense(id: 1, name: "New Laptop", category: .electronics, date: Date(), amount: 150000, notes: "Work laptop", userId: previewUserId),
                    MajorExpense(id: 2, name: "Europe Trip", category: .travel, date: Date().addingTimeInterval(-86400 * 30), amount: 250000, notes: "Vacation", userId: previewUserId),
                    MajorExpense(id: 3, name: "Car Downpayment", category: .vehicle, date: Date().addingTimeInterval(-86400 * 60), amount: 300000, notes: "New Car", userId: previewUserId)
                ]
                if let typed = result as? [T] { return typed }
            }
            
            return []
        }
    }
    
    static var previews: some View {
        let coordinator = MainCoordinator(userId: "preview-user")
        let mockRepo = MockDataFetchRepoService(shouldReturnEmptyData: true)
        
        return NavigationView {
            AllMajorExpensesView(repoService: mockRepo)
                .environmentObject(coordinator)
        }
    }
}
