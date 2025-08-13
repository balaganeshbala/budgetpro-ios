import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var coordinator: MainCoordinator
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    @State private var showingMonthPicker = false
    @State private var tempMonth = Calendar.current.component(.month, from: Date())
    @State private var tempYear = Calendar.current.component(.year, from: Date())
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.groupedBackground
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header with profile and month selector
                    headerView
                    
                    // Main content in ScrollView
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Budget Overview Card
                            if viewModel.isLoading {
                                budgetSkeletonCard
                            } else {
                                budgetOverviewCard
                            }
                            
                            // Only show other sections if budget exists
                            if !viewModel.isLoading && !viewModel.budgetCategories.isEmpty {
                                // Recent Expenses Section
                                expensesSection
                                
                                // Recent Incomes Section
                                incomesSection
                                
                                // Options/Features Section
                                optionsSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.refreshData(month: selectedMonth, year: selectedYear)
        }

        .overlay(
            Group {
                if showingMonthPicker {
                    MonthYearPickerDialog(
                        selectedMonth: $tempMonth,
                        selectedYear: $tempYear,
                        isPresented: $showingMonthPicker,
                        months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                        years: Array(2023...Calendar.current.component(.year, from: Date())),
                        onDone: {
                            selectedMonth = tempMonth
                            selectedYear = tempYear
                            Task {
                                await viewModel.loadData(month: tempMonth, year: tempYear)
                            }
                            showingMonthPicker = false
                        }
                    )
                }
            }
        )
        .onAppear {
            // Only load data on first launch
            if !hasLoadedInitialData {
                hasLoadedInitialData = true
                Task {
                    await viewModel.loadData(month: selectedMonth, year: selectedYear)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .expenseDataChanged)) { _ in
            // Only refresh when data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .incomeDataChanged)) { _ in
        // Only refresh when income data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .budgetDataChanged)) { _ in
            // Only refresh when budget data actually changes
            Task {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
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
    
    // MARK: - Expenses Section
    private var expensesSection: some View {
        VStack(spacing: 16) {
            if viewModel.recentExpenses.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("Expenses")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 40))
                            .foregroundColor(.secondaryText.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No expenses yet")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("Add your first expense to track spending")
                                .font(.sora(14))
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addExpense)
                        }) {
                            Text("Add Expense")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.secondary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("Expenses")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentExpenses.prefix(5).enumerated()), id: \.offset) { index, expense in
                            Button(action: {
                                coordinator.navigate(to: .expenseDetails(expense: expense))
                            }) {
                                ExpenseRowView(expense: expense)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < min(viewModel.recentExpenses.count - 1, 4) {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addExpense)
                        }) {
                            VStack {
                                Divider()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.secondary)
                                    Text("Add New")
                                        .font(.sora(14, weight: .medium))
                                        .foregroundColor(Color.secondary)
                                    Spacer()
                                }
                                .padding(16)
                            }
                        }
                        
                        if !viewModel.recentExpenses.isEmpty {
                            VStack {
                                Divider()
                                Button(action: {
                                    coordinator.navigate(to: .allExpenses(expenses: viewModel.recentExpenses, month: selectedMonth, year: selectedYear))
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("More Details")
                                            .font(.sora(14, weight: .medium))
                                            .foregroundColor(Color.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.secondary)
                                        Spacer()
                                    }
                                    .padding(16)
                                }
                            }
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Incomes Section  
    private var incomesSection: some View {
        VStack(spacing: 16) {
            if viewModel.recentIncomes.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("Incomes")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondaryText.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No incomes yet")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Text("Add your income sources to track earnings")
                                .font(.sora(14))
                                .foregroundColor(.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addIncome)
                        }) {
                            Text("Add Income")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.secondary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("Incomes")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentIncomes.prefix(5).enumerated()), id: \.offset) { index, income in
                            Button(action: {
                                coordinator.navigate(to: .incomeDetails(income: income))
                            }) {
                                IncomeRowView(income: income)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < min(viewModel.recentIncomes.count - 1, 4) {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .addIncome)
                        }) {
                            VStack {
                                Divider()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.secondary)
                                    Text("Add New")
                                        .font(.sora(14, weight: .medium))
                                        .foregroundColor(Color.secondary)
                                    Spacer()
                                }
                                .padding(16)
                            }
                        }
                        
                        if !viewModel.recentIncomes.isEmpty {
                            VStack {
                                Divider()
                                Button(action: {
                                    coordinator.navigate(to: .allIncomes(incomes: viewModel.recentIncomes, month: selectedMonth, year: selectedYear))
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("More Details")
                                            .font(.sora(14, weight: .medium))
                                            .foregroundColor(Color.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.secondary)
                                        Spacer()
                                    }
                                    .padding(16)
                                }
                            }
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Profile Button
                Button(action: {
                    coordinator.navigate(to: .profile)
                }) {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.secondary)
                                .font(.system(size: 20))
                        )
                }
                
                Spacer()
                
                // Month/Year Selector
                MonthYearPicker(
                    selectedMonth: $selectedMonth,
                    selectedYear: $selectedYear,
                    showingPicker: $showingMonthPicker,
                    onChanged: { month, year in
                        Task {
                            await viewModel.loadData(month: month, year: year)
                        }
                    }
                )
                .onChange(of: showingMonthPicker) { isShowing in
                    if isShowing {
                        tempMonth = selectedMonth
                        tempYear = selectedYear
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            
            Divider()
        }
        .background(Color.cardBackground)
    }
    
    // MARK: - Budget Overview Card
    @ViewBuilder
    private var budgetOverviewCard: some View {
        if viewModel.budgetCategories.isEmpty {
            // No budget state - show custom empty state
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Budget Overview")
                        .font(.sora(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
                
                if isPastMonth(month: selectedMonth, year: selectedYear) {
                    // Past month no budget state
                    pastMonthNoBudgetState
                } else {
                    // Current/future month no budget state
                    currentMonthNoBudgetState
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
        } else {
            // Budget exists - use reusable component
            BudgetOverviewCard(
                totalBudget: viewModel.totalBudget,
                totalSpent: viewModel.totalSpent,
                showEditButton: !isPastMonth(month: selectedMonth, year: selectedYear),
                showDetailsButton: true,
                onEditTapped: {
                    coordinator.navigate(to: .editBudget(budgetCategories: viewModel.budgetCategories, month: selectedMonth, year: selectedYear))
                },
                onDetailsTapped: {
                    coordinator.navigate(to: .budgetCategories(budgetCategories: viewModel.budgetCategories, totalBudget: viewModel.totalBudget, expenses: viewModel.recentExpenses, month: selectedMonth, year: selectedYear))
                }
            )
        }
    }
    
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Options content
            VStack(spacing: 0) {
                OptionRow(
                    icon: "chart.pie",
                    iconColor: Color.primary,
                    title: "Savings Analysis",
                    action: {
                        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                        let monthString = monthNames[selectedMonth - 1]
                        let yearString = String(selectedYear)
                        
                        coordinator.navigate(to: .savingsAnalysis(
                            expenses: viewModel.recentExpenses,
                            incomes: viewModel.recentIncomes,
                            totalBudget: viewModel.totalBudget,
                            month: monthString,
                            year: yearString
                        ))
                    }
                )
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Skeleton Loading
    private var budgetSkeletonCard: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondarySystemFill)
                    .frame(width: 120, height: 20)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondarySystemFill)
                            .frame(width: 80, height: 16)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondarySystemFill)
                            .frame(width: 60, height: 16)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Helper Functions
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    private func isPastMonth(month: Int, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        if year < currentYear {
            return true
        } else if year == currentYear && month < currentMonth {
            return true
        }
        return false
    }
    
    // MARK: - Past Month No Budget State
    private var pastMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondaryText)
            
            Text("No Budget Data Available")
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text("Budget data for past months cannot be created. Please select the current month to set a budget.")
                .font(.sora(14))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 16)
        }
        .padding(.all, 16)
    }
    
    // MARK: - Current Month No Budget State
    private var currentMonthNoBudgetState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.secondaryText.opacity(0.6))
            
            Text("No budget created yet")
                .font(.sora(16, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Text("Create your first budget to track your expenses")
                .font(.sora(14))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                coordinator.navigate(to: .createBudget(month: selectedMonth, year: selectedYear))
            }) {
                Text("Create Budget")
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.secondary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 20)
    }
}


// MARK: - Row Views
struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .circular)
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
                    .foregroundColor(.primaryText)
                
                Text(expense.dateString)
                    .font(.sora(12))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text("₹\(formatAmount(expense.amount))")
                .font(.sora(14, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Image(systemName: "chevron.right")
                .font(.sora(14, weight: .semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

struct IncomeRowView: View {
    let income: Income
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .circular)
                .fill(IncomeCategory.from(categoryName: income.category).color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: income.categoryIcon)
                        .foregroundColor(IncomeCategory.from(categoryName: income.category).color)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(income.source)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text(income.dateString)
                    .font(.sora(12))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text("₹\(formatAmount(income.amount))")
                .font(.sora(14, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Image(systemName: "chevron.right")
                .font(.sora(14, weight: .semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}


struct OptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(iconColor)
                            .font(.system(size: 16))
                    )
                
                Text(title)
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)) 
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
