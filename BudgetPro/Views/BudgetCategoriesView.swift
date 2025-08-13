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
    let expenses: [Expense]
    let month: Int
    let year: Int
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var coordinator: MainCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header info
                headerSection
                
                // Budget categories list
                categoriesSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .background(Color.groupedBackground)
        .navigationTitle("\(monthName)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.sora(14))
                        .foregroundColor(.secondaryText)
                    
                    Text("₹\(Int(totalBudget))")
                        .font(.sora(24, weight: .bold))
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
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
        let unplannedCategories = budgetCategories.filter { $0.budget == 0 && $0.spent > 0 }
        let noBudgetCategories = budgetCategories.filter { $0.budget == 0 && $0.spent == 0 }
        let plannedCategories = budgetCategories.filter { $0.budget > 0 }
        
        let sortedPlanned = plannedCategories.sorted { first, second in
            let firstPercentage = first.spent / first.budget
            let secondPercentage = second.spent / second.budget
            return firstPercentage > secondPercentage
        }
        
        return unplannedCategories + sortedPlanned + noBudgetCategories
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
                        
                        Text("\(Int(percentOfTotal))% of total budget")
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
                    Text("Spent")
                        .font(.sora(12))
                        .foregroundColor(.secondaryText)
                    
                    Text("₹\(Int(category.spent))")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(percentageSpent > 1 ? .overBudgetColor : .primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.sora(12))
                        .foregroundColor(.secondaryText)
                    
                    Text("₹\(Int(max(0, category.budget - category.spent)))")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(Color.budgetProgressColor)
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
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
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