import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
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
            }
            .background(Color.gray.opacity(0.1))
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData(month: selectedMonth, year: selectedYear)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .onAppear {
            Task {
                await viewModel.loadData(month: selectedMonth, year: selectedYear)
            }
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
                    onChanged: { month, year in
                        Task {
                            await viewModel.loadData(month: month, year: year)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(Color.white)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
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
                
                HStack(spacing: 12) {
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
                        
                        // More Details Button
                        NavigationLink(destination: BudgetCategoriesView(
                            budgetCategories: viewModel.budgetCategories,
                            totalBudget: viewModel.totalBudget,
                            month: selectedMonth,
                            year: selectedYear
                        )) {
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
                // Budget exists - show summary
                VStack(spacing: 12) {
                    // Total Budget vs Spent
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Budget")
                                .font(.sora(12))
                                .foregroundColor(.gray)
                            
                            Text("₹\(Int(viewModel.totalBudget))")
                                .font(.sora(20, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Spent")
                                .font(.sora(12))
                                .foregroundColor(.gray)
                            
                            Text("₹\(Int(viewModel.totalSpent))")
                                .font(.sora(20, weight: .bold))
                                .foregroundColor(viewModel.totalSpent > viewModel.totalBudget ? .red : Color(red: 0.2, green: 0.6, blue: 0.5))
                        }
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(viewModel.totalSpent > viewModel.totalBudget ? Color.red : Color(red: 0.2, green: 0.6, blue: 0.5))
                                .frame(width: min(geometry.size.width, geometry.size.width * (viewModel.totalSpent / max(viewModel.totalBudget, 1))), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    // Budget Categories Preview (Top 3)
                    if viewModel.budgetCategories.count > 0 {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.budgetCategories.prefix(3).enumerated()), id: \.offset) { index, category in
                                BudgetCategoryRow(category: category)
                            }
                        }
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
            SectionHeader(title: "Expenses") {
                // Navigate to all expenses
            }
            
            if viewModel.recentExpenses.isEmpty {
                EmptyStateCard(
                    icon: "creditcard",
                    title: "No expenses yet",
                    subtitle: "Add your first expense to track spending",
                    buttonTitle: "Add Expense",
                    action: {
                        // Navigate to add expense
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
                    
                    if viewModel.recentExpenses.count > 5 {
                        Button(action: {
                            // Navigate to all expenses
                        }) {
                            HStack {
                                Spacer()
                                Text("View All (\(viewModel.recentExpenses.count))")
                                    .font(.sora(14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
            SectionHeader(title: "Incomes") {
                // Navigate to all incomes
            }
            
            if viewModel.recentIncomes.isEmpty {
                EmptyStateCard(
                    icon: "plus.circle",
                    title: "No income recorded",
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
                                Text("View All (\(viewModel.recentIncomes.count))")
                                    .font(.sora(14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
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
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.black)
                
                Text("₹\(Int(category.spent)) / ₹\(Int(category.budget))")
                    .font(.sora(12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Progress indicator
            Circle()
                .fill(category.spent > category.budget ? Color.red : Color(red: 0.2, green: 0.6, blue: 0.5))
                .frame(width: 8, height: 8)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
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
                
                Text(expense.category)
                    .font(.sora(12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(Int(expense.amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(expense.dateString)
                    .font(.sora(11))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
    }
}

struct IncomeRow: View {
    let income: Income
    
    var body: some View {
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
                Text(income.name)
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.black)
                
                Text(income.category)
                    .font(.sora(12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(Int(income.amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                
                Text(income.dateString)
                    .font(.sora(11))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
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
                    .font(.sora(16))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(16)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
