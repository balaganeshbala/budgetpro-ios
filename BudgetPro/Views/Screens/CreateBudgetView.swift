//
//  CreateBudgetView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//

import SwiftUI

struct CreateBudgetView: View {
    @StateObject private var viewModel: CreateBudgetViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @State private var showingSuccessAlert = false
    
    let month: Int
    let year: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
        self._viewModel = StateObject(wrappedValue: CreateBudgetViewModel(month: month, year: year))
    }
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // Header info
                    headerSection

                    // Total Budget Summary
                    totalBudgetCard

                    // Budget Categories
                    budgetCategoriesSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .disableScrollViewBounce()
        }
        .navigationTitle("Create Budget")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveBudget()
                    }
                }
                .font(.sora(16, weight: .medium))
                .foregroundColor(viewModel.canSave ? .adaptiveSecondary : .secondaryText)
                .disabled(!viewModel.canSave || viewModel.isLoading)
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Budget created successfully!")
        }
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                showingSuccessAlert = true
            }
        }
        .onAppear {
            viewModel.loadExistingBudget()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set your budget for \(monthName) \(String(year))")
                .font(.sora(16))
                .foregroundColor(.secondaryText)
            
            Text("Enter budget amounts for each category to track your spending throughout the month.")
                .font(.sora(14))
                .foregroundColor(.secondaryText.opacity(0.8))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Total Budget Card
    private var totalBudgetCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total Budget")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("₹\(Int(viewModel.totalBudget))")
                    .font(.sora(24, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Budget Categories Section
    private var budgetCategoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Budget Categories")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            
            LazyVStack(spacing: 12) {
                ForEach(ExpenseCategory.userSelectableCategories, id: \.self) { category in
                    BudgetCategoryInput(
                        category: category,
                        amount: viewModel.categoryBudgets[category.displayName] ?? 0,
                        onAmountChanged: { amount in
                            viewModel.updateCategoryBudget(category.displayName, amount: amount)
                        }
                    )
                }
            }
        }
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Budget Category Input Field
struct BudgetCategoryInput: View {
    let category: ExpenseCategory
    let amount: Double
    let onAmountChanged: (Double) -> Void
    
    @State private var textAmount: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Circle()
                .fill(category.color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(category.color)
                )
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                if amount > 0 {
                    Text("₹\(Int(amount))")
                        .font(.sora(12))
                        .foregroundColor(.secondaryText)
                } else {
                    Text("No budget set")
                        .font(.sora(12))
                        .foregroundColor(.secondaryText.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Amount Input
            VStack(spacing: 8) {
                HStack {
                    Text("₹")
                        .font(.sora(16))
                        .foregroundColor(.secondaryText)
                    
                    TextField("0", text: $textAmount)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.primaryText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.adaptiveSecondary : Color.inputBorder, lineWidth: isFocused ? 2 : 1)
                        .background(Color.inputBackground)
                )
                .cornerRadius(8)
            }
            .frame(width: 100)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
        .onAppear {
            textAmount = amount > 0 ? String(Int(amount)) : ""
        }
        .onChange(of: textAmount) { newValue in
            let cleanedValue = newValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if cleanedValue != newValue {
                textAmount = cleanedValue
            }
            
            let numericValue = Double(cleanedValue) ?? 0
            onAmountChanged(numericValue)
        }
        .onChange(of: amount) { newAmount in
            if !isFocused {
                textAmount = newAmount > 0 ? String(Int(newAmount)) : ""
            }
        }
    }
}

struct CreateBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateBudgetView(month: 7, year: 2025)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            CreateBudgetView(month: 7, year: 2025)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
