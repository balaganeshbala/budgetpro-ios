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
                // White background that extends to status bar
                Color.white
                    .ignoresSafeArea(.all, edges: .top)
                
                ScrollView {
                VStack(spacing: 0) {
                    // Header with profile and month selector
                    headerView
                    
                    // Main content
                    LazyVStack(spacing: 20) {
                        // Budget Overview Card
                        if viewModel.isLoading {
                            budgetSkeletonCard
                        } else {
                            budgetOverviewCard
                        }
                        
                        // Recent Expenses Section
                        recentExpensesSection
                        
                        // Recent Incomes Section
                        recentIncomesSection
                        
                        // Options/Features Section
                        optionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .background(Color.gray.opacity(0.1))
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
                        .fill(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.2))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
                    // Edit Budget Button
                    NavigationLink(destination: EditBudgetView(
                        budgetCategories: viewModel.budgetCategories,
                        month: selectedMonth,
                        year: selectedYear
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                            
                            Text("Edit")
                                .font(.sora(14))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.1))
                        .cornerRadius(16)
                    }
                }
            }
            
            if viewModel.budgetCategories.isEmpty {
                // No Budget State
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
                            .background(Color(red: 1.0, green: 0.4, blue: 0.4))
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 20)
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
                                    .foregroundColor(viewModel.totalSpent > viewModel.totalBudget ? .red : Color(red: 0.2, green: 0.6, blue: 0.5))
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.05) : Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.05),
                                    viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.1) : Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.totalSpent > viewModel.totalBudget ? Color.red.opacity(0.2) : Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.2), lineWidth: 1)
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
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
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
        VStack(spacing: 12) {
            SectionHeader(title: "Expenses", showMoreButton: false)
            
            if viewModel.recentExpenses.isEmpty {
                EmptyStateCard(
                    icon: "creditcard",
                    title: "No expenses yet",
                    subtitle: "Add your first expense to track spending",
                    buttonTitle: "Add Expense",
                    action: {
                        showingAddExpense = true
                    }
                )
            } else {
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
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                            Text("Add New")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.05))
                    }
                    
                    if viewModel.recentExpenses.count > 5 {
                        Button(action: {
                            showingAllExpenses = true
                        }) {
                            HStack {
                                Spacer()
                                Text("More Details")
                                    .font(.sora(14, weight: .medium))
                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                Spacer()
                            }
                            .padding(16)
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
        VStack(spacing: 12) {
            SectionHeader(title: "Incomes", showMoreButton: false)
            
            if viewModel.recentIncomes.isEmpty {
                EmptyStateCard(
                    icon: "dollarsign.circle",
                    title: "No incomes yet",
                    subtitle: "Add your income sources to track earnings",
                    buttonTitle: "Add Income",
                    action: {
                        // Navigate to add income
                    }
                )
            } else {
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
                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                Spacer()
                            }
                            .padding(16)
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
        VStack(spacing: 12) {
            SectionHeader(title: "Quick Actions", showMoreButton: false)
            
            VStack(spacing: 0) {
                OptionRow(
                    icon: "chart.pie",
                    iconColor: Color(red: 0.2, green: 0.6, blue: 0.5),
                    title: "Savings Analysis",
                    action: {
                        // Navigate to savings analysis
                    }
                )
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
        }
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
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
                    .background(Color(red: 1.0, green: 0.4, blue: 0.4))
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
            HStack {
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
                    .fill(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: income.categoryIcon)
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
