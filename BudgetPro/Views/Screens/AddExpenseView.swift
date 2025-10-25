//
//  AddExpenseView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 17/07/25.
//

import SwiftUI

// MARK: - Add Expense View
struct AddExpenseView: View {
    
    @StateObject private var viewModel: AddExpenseViewModel
    
    init(repoService: TransactionRepoService) {
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(repoService: repoService))
    }
    
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
        AddExpenseView(repoService: SupabaseTransactionRepoService(transactionType: .expense))
    }
}
