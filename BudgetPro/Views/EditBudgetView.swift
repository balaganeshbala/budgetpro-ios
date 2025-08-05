//
//  EditBudgetView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct EditBudgetView: View {
    @StateObject private var viewModel: EditBudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSuccessAlert = false
    @State private var showingConfirmDialog = false
    
    let month: Int
    let year: Int
    
    init(budgetCategories: [BudgetCategory], month: Int, year: Int) {
        self.month = month
        self.year = year
        self._viewModel = StateObject(wrappedValue: EditBudgetViewModel(budgetCategories: budgetCategories, month: month, year: year))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            totalBudgetCard
            
            ScrollView {
                // Budget Categories
                budgetCategoriesSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }
            .background(Color.gray.opacity(0.1))
            
            // Update Button at bottom
            updateButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color.white)
        }
        .navigationTitle("Edit Budget")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Update", isPresented: $showingConfirmDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Update") {
                Task {
                    await viewModel.updateBudget()
                }
            }
        } message: {
            Text("Are you sure you want to update this budget?")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Budget updated successfully!")
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
    }
    
    // MARK: - Total Budget Card
    private var totalBudgetCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.sora(14))
                        .foregroundColor(.gray)
                    
                    Text("₹\(Int(viewModel.totalBudget))")
                        .font(.sora(24, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                }
                
                Spacer()
                
                if viewModel.hasChanges {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text("Modified")
                            .font(.sora(12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Budget Categories Section
    private var budgetCategoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Budget Categories")
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.editableBudgets.indices, id: \.self) { index in
                    let editableBudget = viewModel.editableBudgets[index]
                    EditBudgetCategoryInput(
                        budgetCategory: editableBudget,
                        originalAmount: viewModel.originalBudgets[editableBudget.category.displayName] ?? 0,
                        onAmountChanged: { newAmount in
                            viewModel.updateCategoryBudget(editableBudget.category.displayName, amount: newAmount)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Update Button
    private var updateButton: some View {
        Button(action: {
            if viewModel.hasChanges {
                showingConfirmDialog = true
            } else {
                viewModel.errorMessage = "No changes made to the budget"
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Update Budget")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.canUpdate && viewModel.hasChanges && !viewModel.isLoading
                    ? Color.secondary
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.canUpdate || !viewModel.hasChanges || viewModel.isLoading)
        .padding(.top, 16)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
}

struct EditBudgetCategoryInput: View {
    let budgetCategory: EditableBudgetCategory
    let originalAmount: Double
    let onAmountChanged: (Double) -> Void
    
    @State private var textAmount: String
    @FocusState private var isFocused: Bool
    
    init(budgetCategory: EditableBudgetCategory, originalAmount: Double, onAmountChanged: @escaping (Double) -> Void) {
        self.budgetCategory = budgetCategory
        self.originalAmount = originalAmount
        self.onAmountChanged = onAmountChanged
        
        // Initialize textAmount with the budget amount from the EditableBudgetCategory
        // For existing budgets, show the amount even if the system thinks it should be 0
        // Use originalAmount as fallback if budgetCategory.amount is 0
        let amountToShow = budgetCategory.amount > 0 ? budgetCategory.amount : originalAmount
        let initialText = amountToShow > 0 ? String(Int(amountToShow)) : ""
        self._textAmount = State(initialValue: initialText)
    }
    
    private var hasChanged: Bool {
        return budgetCategory.amount != originalAmount
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Circle()
                .fill(budgetCategory.category.color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: budgetCategory.category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(budgetCategory.category.color)
                )
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(budgetCategory.category.displayName)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.black)
                    
                    if hasChanged {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.orange)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("Current: ₹\(Int(budgetCategory.amount))")
                        .font(.sora(12))
                        .foregroundColor(hasChanged ? .orange : .gray)
                    
                    if hasChanged && originalAmount != budgetCategory.amount {
                        Text("(was ₹\(Int(originalAmount)))")
                            .font(.sora(11))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Amount Input
            VStack(spacing: 8) {
                HStack {
                    Text("₹")
                        .font(.sora(16))
                        .foregroundColor(.gray)
                    
                    TextField("0", text: $textAmount)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.black)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            hasChanged ? Color.orange : 
                            (isFocused ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3)), 
                            lineWidth: hasChanged ? 2 : (isFocused ? 2 : 1)
                        )
                        .background(Color.white)
                )
                .cornerRadius(8)
            }
            .frame(width: 100)
        }
        .padding(16)
        .background(hasChanged ? Color.orange.opacity(0.05) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasChanged ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
        .onChange(of: textAmount) { newValue in
            let cleanedValue = newValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if cleanedValue != newValue {
                textAmount = cleanedValue
            }
            
            let numericValue = Double(cleanedValue) ?? 0
            onAmountChanged(numericValue)
        }
        .onChange(of: budgetCategory.amount) { newAmount in
            // Only update if field is not focused and the amount actually changed
            if !isFocused && textAmount != String(Int(newAmount)) {
                textAmount = newAmount > 0 ? String(Int(newAmount)) : ""
            }
        }
    }
}

struct EditBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        EditBudgetView(
            budgetCategories: [
                BudgetCategory(id: "1", name: "Food", budget: 15000, spent: 12000),
                BudgetCategory(id: "2", name: "Transport", budget: 8000, spent: 9500)
            ],
            month: 7,
            year: 2025
        )
    }
}
