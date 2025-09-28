//
//  CategoryDetailView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/08/25.
//

import SwiftUI

struct CategoryDetailView: View {
    let category: BudgetCategory
    let expenses: [Expense]
    let month: Int
    let year: Int
    
    @Environment(\.presentationMode) var presentationMode
    
    // Filter expenses for this category
    private var categoryExpenses: [Expense] {
        expenses.filter { expense in
            expense.category.displayName == category.name
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header
            categoryHeader
            
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Overview Card (reused from HomeView but without buttons)
                    budgetOverviewCard
                    
                    // Transactions Section
                    transactionsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .disableScrollViewBounce()
        }
        .background(Color.groupedBackground)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)

    }
    
    // MARK: - Budget Overview Card (Reusable Component)
    private var budgetOverviewCard: some View {
        BudgetOverviewCard(
            title: "\(category.name) Budget",
            totalBudget: category.budget,
            totalSpent: category.spent,
            showEditButton: false,
            showDetailsButton: false
        )
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(spacing: 16) {
            if categoryExpenses.isEmpty {
                emptyTransactionsView
            } else {
                transactionsListView
            }
        }
    }
    
    private var transactionsListView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Transactions")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(categoryExpenses.count) items")
                    .font(.sora(14))
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Use the new TransactionsTable
            TransactionsTable(transactions: categoryExpenses)
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Transactions")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                Image(systemName: "creditcard")
                    .font(.system(size: 40))
                    .foregroundColor(.secondaryText.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("No transactions yet")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text("No expenses found for \(category.name) category")
                        .font(.sora(14))
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 20)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    

    
    // MARK: - Category Header
    private var categoryHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(categoryColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.sora(20, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    Text(monthName)
                        .font(.sora(14))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.cardBackground)
    }
    
    // MARK: - Helper Functions
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    private var categoryColor: Color {
        return ExpenseCategory.from(categoryName: category.name).color
    }
    
    private var categoryIcon: String {
        return ExpenseCategory.from(categoryName: category.name).iconName
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryDetailView(
                category: BudgetCategory(id: "1", name: "Food", budget: 15000, spent: 12000),
                expenses: [
                    Expense(
                        id: 1,
                        name: "Grocery Shopping",
                        amount: 2500,
                        category: .food,
                        date: Date().addingTimeInterval(-86400 * 2) // 2 days ago
                    ),
                    Expense(
                        id: 2,
                        name: "Restaurant Dinner",
                        amount: 1800,
                        category: .food,
                        date: Date().addingTimeInterval(-86400 * 5) // 5 days ago
                    ),
                    Expense(
                        id: 3,
                        name: "Coffee Shop",
                        amount: 450,
                        category: .food,
                        date: Date().addingTimeInterval(-86400 * 1) // 1 day ago
                    ),
                    Expense(
                        id: 4,
                        name: "Lunch Delivery",
                        amount: 650,
                        category: .food,
                        date: Date().addingTimeInterval(-86400 * 3) // 3 days ago
                    ),
                    Expense(
                        id: 5,
                        name: "Snacks & Beverages",
                        amount: 320,
                        category: .food,
                        date: Date().addingTimeInterval(-86400 * 7) // 1 week ago
                    )
                ],
                month: 7,
                year: 2025
            )
        }
    }
}
