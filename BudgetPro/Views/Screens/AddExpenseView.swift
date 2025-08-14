//
//  AddExpenseView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 17/07/25.
//

import SwiftUI

// MARK: - Add Expense View
struct AddExpenseView: View {
    @StateObject private var viewModel = AddExpenseViewModel()
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .expense,
            mode: .add,
            categories: ExpenseCategory.userSelectableCategories,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}

struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
    }
}
