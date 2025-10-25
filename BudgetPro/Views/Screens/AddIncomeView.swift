//
//  AddIncomeView.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import SwiftUI

struct AddIncomeView: View {
    @StateObject private var viewModel: AddIncomeViewModel
    
    init(repoService: TransactionRepoService) {
        _viewModel = StateObject(wrappedValue: AddIncomeViewModel(repoService: repoService))
    }
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .income,
            mode: .add,
            categories: IncomeCategory.userSelectableCategories,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}

struct AddIncomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddIncomeView(repoService: SupabaseTransactionRepoService(transactionType: .income))
        }
    }
}
