import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingProfile = false
    @State private var showingAllExpenses = false
    @State private var showingAddExpense = false
    @State private var showingMonthPicker = false
    @State private var tempMonth = Calendar.current.component(.month, from: Date())
    @State private var tempYear = Calendar.current.component(.year, from: Date())
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gray background that extends to full screen
                Color.gray.opacity(0.1)
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
                                recentExpensesSection
                                
                                // Recent Incomes Section
                                recentIncomesSection
                                
                                // Options/Features Section
                                optionsSection
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingAllExpenses) {
            AllExpensesView(
                expenses: viewModel.recentExpenses,
                month: selectedMonth,
                year: selectedYear
            )
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
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
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Profile Button
                Button(action: {
                    showingProfile = true
                }) {
                    Circle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.primary)
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
        .background(Color.white)
    }
    
    // MARK: - Budget Overview Card
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Budget Overview")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                if !viewModel.budgetCategories.isEmpty {
                    // Edit Budget Button - Only show for current and future months
                    if !isPastMonth(month: selectedMonth, year: selectedYear) {
                        NavigationLink(destination: EditBudgetView(
                            budgetCategories: viewModel.budgetCategories,
                            month: selectedMonth,
                            year: selectedYear
                        )) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.secondary)
                                
                                Text("Edit")
                                    .font(.sora(14))
                                    .foregroundColor(Color.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                }
            }
            
            if viewModel.budgetCategories.isEmpty {
                if isPastMonth(month: selectedMonth, year: selectedYear) {
                    // Past month no budget state
                    pastMonthNoBudgetState
                } else {
                    // Current/future month no budget state
                    currentMonthNoBudgetState
                }
            } else {
                // Budget exists - show summary with remaining amount highlighted on top
                VStack(spacing: 20) {
                    // Remaining Amount - Highlighted at the top
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Remaining Budget")
                                    .font(.sora(18, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("₹\(formatAmount(max(0, viewModel.totalBudget - viewModel.totalSpent)))")
                                    .font(.sora(30, weight: .bold))
                                    .foregroundColor(viewModel.totalSpent > viewModel.totalBudget ? .red : Color.primary)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.05) : Color.primary.opacity(0.05),
                                    viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.1) : Color.primary.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.2) : Color.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Budget Summary Row
                    HStack(spacing: 16) {
                        // Total Budget
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.sora(14))
                                .foregroundColor(.gray)
                            
                            Text("₹\(formatAmount(viewModel.totalBudget))")
                                .font(.sora(20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 30)
                        
                        // Total Spent
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Spent")
                                .font(.sora(14))
                                .foregroundColor(.gray)
                            
                            Text("₹\(formatAmount(viewModel.totalSpent))")
                                .font(.sora(20, weight: .semibold))
                                .foregroundColor(viewModel.totalSpent > viewModel.totalBudget ? .red : .orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Progress Bar with Percentage
                    VStack(spacing: 8) {
                        HStack {
                            Text("Budget Usage")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int((viewModel.totalSpent / max(viewModel.totalBudget, 1)) * 100))%")
                                .font(.sora(16, weight: .bold))
                                .foregroundColor(viewModel.totalSpent > viewModel.totalBudget ? .red : .orange)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 10)
                                    .cornerRadius(5)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                viewModel.totalSpent > viewModel.totalBudget ? Color.red : Color.orange,
                                                viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.8) : Color.orange.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(geometry.size.width, geometry.size.width * (viewModel.totalSpent / max(viewModel.totalBudget, 1))), height: 10)
                                    .cornerRadius(5)
                                    .animation(.easeInOut(duration: 0.5), value: viewModel.totalSpent)
                            }
                        }
                        .frame(height: 10)
                    }
                    
                    // More Details Button
                    NavigationLink(destination: BudgetCategoriesView(
                        budgetCategories: viewModel.budgetCategories,
                        totalBudget: viewModel.totalBudget,
                        month: selectedMonth,
                        year: selectedYear
                    )) {
                        HStack {
                            Text("View Budget Details")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(Color.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.secondary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Recent Expenses Section
    private var recentExpensesSection: some View {
        VStack(spacing: 16) {
            if viewModel.recentExpenses.isEmpty {
                // Header inside empty state card
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Expenses")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    
                    // Empty state content
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No expenses yet")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("Add your first expense to track spending")
                                .font(.sora(14))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            showingAddExpense = true
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
            } else {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Expenses")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Expenses list
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentExpenses.prefix(5).enumerated()), id: \.offset) { index, expense in
                            ExpenseRow(expense: expense)
                            
                            if index < min(viewModel.recentExpenses.count - 1, 4) {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        // Add New Expense Button
                        NavigationLink(destination: AddExpenseView()) {
                            HStack {
                                Spacer()
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.primary)
                                Text("Add New")
                                    .font(.sora(14, weight: .medium))
                                    .foregroundColor(Color.primary)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.primary.opacity(0.05))
                        }
                        
                        if viewModel.recentExpenses.count > 5 {
                            Button(action: {
                                showingAllExpenses = true
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Recent Incomes Section
    private var recentIncomesSection: some View {
        VStack(spacing: 16) {
            if viewModel.recentIncomes.isEmpty {
                // Header inside empty state card
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Incomes")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    
                    // Empty state content
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No incomes yet")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("Add your income sources to track earnings")
                                .font(.sora(14))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            // Navigate to add income
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
            } else {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Incomes")
                            .font(.sora(18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Incomes list
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentIncomes.prefix(5).enumerated()), id: \.offset) { index, income in
                            IncomeRow(income: income)
                            
                            if index < min(viewModel.recentIncomes.count - 1, 4) {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        if viewModel.recentIncomes.count > 5 {
                            Button(action: {
                                // Navigate to all incomes
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
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
                        // Navigate to savings analysis
                    }
                )
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Skeleton Loading
    private var budgetSkeletonCard: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 20)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 16)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 16)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
                .foregroundColor(.gray)
            
            Text("No Budget Data Available")
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Budget data for past months cannot be created. Please select the current month to set a budget.")
                .font(.sora(14))
                .foregroundColor(.gray)
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
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No budget created yet")
                .font(.sora(16, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Create your first budget to track your expenses")
                .font(.sora(14))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: CreateBudgetView(month: selectedMonth, year: selectedYear)) {
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

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let showMoreButton: Bool
    let moreAction: (() -> Void)?
    
    init(title: String, showMoreButton: Bool = true, moreAction: (() -> Void)? = nil) {
        self.title = title
        self.showMoreButton = showMoreButton
        self.moreAction = moreAction
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            if showMoreButton, let action = moreAction {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text("More")
                            .font(.sora(14))
                            .foregroundColor(Color.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.gray)
                
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
                    .background(Color.secondary)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        NavigationLink(destination: ExpenseDetailsView(expense: expense)) {
            HStack(spacing: 10) {
                // Category icon
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
                        .foregroundColor(.black)
                    
                    Text(expense.dateString)
                        .font(.sora(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(formatExpenseAmount(expense.amount))")
                    .font(.sora(14, weight: .semibold))
                
                Image(systemName: "chevron.right")
                    .font(.sora(14, weight: .semibold))
                    .foregroundStyle(Color.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
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

struct IncomeRow: View {
    let income: Income
    
    var body: some View {
        NavigationLink(destination: Text("Income Details")) { // Replace with actual income details view
            HStack {
                // Category icon
                Circle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: income.categoryIcon)
                            .foregroundColor(Color.primary)
                            .font(.system(size: 16))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(income.source)
                        .font(.sora(14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(income.dateString)
                        .font(.sora(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(formatIncomeAmount(income.amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(Color.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatIncomeAmount(_ amount: Double) -> String {
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
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MonthYearSelector: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let onSelectionChanged: () -> Void
    
    private let monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        HStack {
            Spacer()
            
            Menu {
                ForEach(1...12, id: \.self) { month in
                    Button(action: {
                        selectedMonth = month
                        onSelectionChanged()
                    }) {
                        HStack {
                            Text(monthNames[month])
                            if selectedMonth == month {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(monthNames[selectedMonth])
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            Text("-")
                .font(.sora(16, weight: .medium))
                .foregroundColor(.white)
            
            Menu {
                ForEach((2020...2030).reversed(), id: \.self) { year in
                    Button(action: {
                        selectedYear = year
                        onSelectionChanged()
                    }) {
                        HStack {
                            Text("\(year)")
                            if selectedYear == year {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(selectedYear)")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
    }
}


// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
