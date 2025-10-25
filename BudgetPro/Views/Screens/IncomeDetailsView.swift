//
//  IncomeDetailsView.swift
//  BudgetPro
//
//  Created by Claude on 04/08/25.
//

import SwiftUI

struct IncomeDetailsView: View {
    @StateObject private var viewModel: IncomeDetailsViewModel
    let income: Income
    
    init(income: Income, repoSerice: TransactionRepoService) {
        self.income = income
        self._viewModel = StateObject(wrappedValue: IncomeDetailsViewModel(income: income, repoService: repoSerice))
    }
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .income,
            mode: .update,
            categories: IncomeCategory.userSelectableCategories,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}

struct IncomeDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeDetailsView(
            income: Income(
                id: 1,
                source: "Salary",
                amount: 50000.0,
                category: .salary,
                date: Date()
            ),
            repoSerice: SupabaseTransactionRepoService(transactionType: .income)
        )
    }
}
