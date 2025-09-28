//
//  BudgetCategoriesView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct BudgetCategoriesView: View {
    let budgetCategories: [BudgetCategory]
    let totalBudget: Double
    let totalSpent: Double
    let expenses: [Expense]
    let month: Int
    let year: Int
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var coordinator: MainCoordinator
    
    // Filter state
    @State private var selectedCategoryNames: Set<String> = []
    @State private var showingFilterSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Header info
                BudgetOverviewCard(
                    title: "Overall Budget",
                    totalBudget: filteredTotalBudget,
                    totalSpent: filteredTotalSpent,
                    showEditButton: false,
                    showDetailsButton: false
                )
                
                // Budget categories list
                categoriesSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .disableScrollViewBounce()
        .background(Color.groupedBackground)
        .navigationTitle("\(monthName)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            CategoryFilterView(
                availableCategories: availableCategoryNames,
                selectedCategories: $selectedCategoryNames
            )
        }
        .onAppear {
            initializeSelectedCategories()
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("By Category")
                    .font(.sora(18, weight: .semibold))
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
    
    private var sortedCategories: [BudgetCategory] {
        // Filter out unknown categories
        let validCategories = budgetCategories.filter { category in
            ExpenseCategory.from(categoryName: category.name) != .unknown
        }
        
        // Apply category filter
        let filteredCategories = validCategories.filter { category in
            selectedCategoryNames.contains(category.name)
        }
        
        let unplannedCategories = filteredCategories.filter { $0.budget == 0 && $0.spent > 0 }
        let noBudgetCategories = filteredCategories.filter { $0.budget == 0 && $0.spent == 0 }
        let plannedCategories = filteredCategories.filter { $0.budget > 0 }
        
        let sortedPlanned = plannedCategories.sorted { first, second in
            let firstPercentage = first.spent / first.budget
            let secondPercentage = second.spent / second.budget
            return firstPercentage > secondPercentage
        }
        
        return unplannedCategories + sortedPlanned + noBudgetCategories
    }
    
    // MARK: - Filter Helper Properties
    private var availableCategoryNames: [String] {
        let validCategories = budgetCategories.filter { category in
            ExpenseCategory.from(categoryName: category.name) != .unknown
        }
        return validCategories.map { $0.name }.sorted()
    }
    
    private var filteredTotalBudget: Double {
        let filteredCategories = budgetCategories.filter { category in
            selectedCategoryNames.contains(category.name) && 
            ExpenseCategory.from(categoryName: category.name) != .unknown
        }
        return filteredCategories.reduce(0) { $0 + $1.budget }
    }
    
    private var filteredTotalSpent: Double {
        let filteredCategories = budgetCategories.filter { category in
            selectedCategoryNames.contains(category.name) && 
            ExpenseCategory.from(categoryName: category.name) != .unknown
        }
        return filteredCategories.reduce(0) { $0 + $1.spent }
    }
    
    // MARK: - Filter Helper Methods
    private func initializeSelectedCategories() {
        if selectedCategoryNames.isEmpty {
            selectedCategoryNames = Set(availableCategoryNames)
        }
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM YYYY"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
}

struct BudgetCategoryCard: View {
    let category: BudgetCategory
    let totalBudget: Double
    
    private var percentageSpent: Double {
        category.budget > 0 ? (category.spent / category.budget) : 0
    }
    
    private var percentOfTotal: Double {
        totalBudget > 0 ? (category.budget / totalBudget * 100) : 0
    }
    
    private var statusInfo: (text: String, color: Color) {
        if category.budget == 0 && category.spent > 0 {
            return ("Unplanned", .adaptiveSecondary)
        } else if category.budget == 0 {
            return ("No Budget", .secondaryText)
        } else if percentageSpent > 1 {
            return ("Overspent", .overBudgetColor)
        } else {
            return ("On Track", .successColor)
        }
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                // Header row
                HStack {
                    // Category icon and name
                    HStack(spacing: 12) {
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 16))
                                    .foregroundColor(categoryColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(.primaryText)
                            
                            Text("\(String(format: percentOfTotal < 1 && percentOfTotal > 0 ? "%.2f" : "%.0f", percentOfTotal))% of total budget")
                                .font(.sora(12))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(statusInfo.text)
                        .font(.sora(11, weight: .medium))
                        .foregroundColor(statusInfo.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusInfo.color.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // Budget amounts
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.sora(12))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(Int(category.budget))")
                            .font(.sora(16, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.sora(12))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(Int(category.budget - category.spent))")
                            .font(.sora(16, weight: .semibold))
                            .foregroundColor(percentageSpent > 1 ? .overBudgetColor : .primaryText)
                    }
                }
                
                // Progress bar
                if category.budget > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondarySystemFill)
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(percentageSpent > 1 ? Color.overBudgetColor : Color.budgetProgressColor)
                                .frame(width: min(geometry.size.width, geometry.size.width * percentageSpent), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }
    
    // Helper computed properties for category styling
    private var categoryColor: Color {
        return ExpenseCategory.from(categoryName: category.name).color
    }
    
    private var categoryIcon: String {
        return ExpenseCategory.from(categoryName: category.name).iconName
    }
}

struct BudgetCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            NavigationView {
                BudgetCategoriesView(
                    budgetCategories: [
                        BudgetCategory(id: "1", name: "Food", budget: 15000, spent: 12000),
                        BudgetCategory(id: "2", name: "Transport", budget: 8000, spent: 9500),
                        BudgetCategory(id: "3", name: "Entertainment", budget: 5000, spent: 3200)
                    ],
                    totalBudget: 28000,
                    totalSpent: 0,
                    expenses: [],
                    month: 7,
                    year: 2025
                )
            }
            .environmentObject(MainCoordinator())
            .preferredColorScheme(.light)
            
            // Dark mode preview
            NavigationView {
                BudgetCategoriesView(
                    budgetCategories: [
                        BudgetCategory(id: "1", name: "Food", budget: 15000, spent: 12000),
                        BudgetCategory(id: "2", name: "Transport", budget: 8000, spent: 9500),
                        BudgetCategory(id: "3", name: "Entertainment", budget: 5000, spent: 3200)
                    ],
                    totalBudget: 28000,
                    totalSpent: 24700,
                    expenses: [],
                    month: 7,
                    year: 2025
                )
            }
            .environmentObject(MainCoordinator())
            .preferredColorScheme(.dark)
        }
    }
}
