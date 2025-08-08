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
            ExpenseCategory.from(categoryName: expense.category).displayName == category.name
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
        }
        .background(Color.gray.opacity(0.1))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)

    }
    
    // MARK: - Budget Overview Card (Simplified)
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Budget Overview")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            // Budget content
            VStack(spacing: 20) {
                // Remaining Amount - Highlighted at the top
                VStack(alignment: .center, spacing: 8) {
                    Text("Remaining Budget")
                        .font(.sora(18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("₹\(formatAmount(max(0, category.budget - category.spent)))")
                        .font(.sora(30, weight: .bold))
                        .foregroundColor(category.spent > category.budget ? .red : Color.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            category.spent > category.budget ? Color.red.opacity(0.05) : Color.primary.opacity(0.05),
                            category.spent > category.budget ? Color.red.opacity(0.1) : Color.primary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(category.spent > category.budget ? Color.red.opacity(0.2) : Color.primary.opacity(0.2), lineWidth: 1)
                )
                
                // Budget Summary Row
                HStack(spacing: 16) {
                    // Total Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.sora(14))
                            .foregroundColor(.gray)
                        
                        Text("₹\(formatAmount(category.budget))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Total Spent
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent")
                            .font(.sora(14))
                            .foregroundColor(.gray)
                        
                        Text("₹\(formatAmount(category.spent))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(category.spent > category.budget ? .red : .orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Progress Bar with Percentage (only if budget > 0)
                if category.budget > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Budget Usage")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int((category.spent / max(category.budget, 1)) * 100))%")
                                .font(.sora(16, weight: .bold))
                                .foregroundColor(category.spent > category.budget ? .red : .orange)
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
                                                category.spent > category.budget ? Color.red : Color.orange,
                                                category.spent > category.budget ? Color.red.opacity(0.8) : Color.orange.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(geometry.size.width, geometry.size.width * (category.spent / max(category.budget, 1))), height: 10)
                                    .cornerRadius(5)
                                    .animation(.easeInOut(duration: 0.5), value: category.spent)
                            }
                        }
                        .frame(height: 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(categoryExpenses.count) items")
                    .font(.sora(14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Use the new TransactionsTable
            TransactionsTable(transactions: categoryExpenses)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Transactions")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                Image(systemName: "creditcard")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("No transactions yet")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("No expenses found for \(category.name) category")
                        .font(.sora(14))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 20)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
                        .foregroundColor(.black)
                    
                    Text(monthName)
                        .font(.sora(14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.white)
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

// MARK: - Category Expense Row View
struct CategoryExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            Text("₹\(formatAmount(expense.amount))")
                .font(.sora(14, weight: .semibold))
                .foregroundColor(.black)
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

// MARK: - Preview
struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryDetailView(
                category: BudgetCategory(id: "1", name: "Food", budget: 15000, spent: 12000),
                expenses: [],
                month: 7,
                year: 2025
            )
        }
    }
}