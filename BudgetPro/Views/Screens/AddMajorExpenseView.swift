//
//  AddMajorExpenseView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import SwiftUI

// MARK: - Add Major Expense View
struct AddMajorExpenseView: View {
    @StateObject private var viewModel: AddMajorExpenseViewModel
    
    init(repoService: TransactionRepoService) {
        _viewModel = StateObject(wrappedValue: AddMajorExpenseViewModel(repoService: repoService))
    }
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .majorExpense,
            mode: .add,
            categories: MajorExpenseCategory.allCases,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}

// MARK: - Preview
struct AddMajorExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddMajorExpenseView(repoService: SupabaseTransactionRepoService(transactionType: .majorExpense))
        }
    }
}
