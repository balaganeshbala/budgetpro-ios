//
//  MajorExpenseDetailsView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 21/09/25.
//

import SwiftUI

struct MajorExpenseDetailsView: View {
    @StateObject private var viewModel: MajorExpenseDetailsViewModel
    let majorExpense: MajorExpense
    
    init(majorExpense: MajorExpense, repoService: TransactionRepoService) {
        self.majorExpense = majorExpense
        self._viewModel = StateObject(wrappedValue: MajorExpenseDetailsViewModel(majorExpense: majorExpense, repoService: repoService))
    }
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .majorExpense,
            mode: .update,
            categories: MajorExpenseCategory.allCases,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}

// MARK: - Preview
struct MajorExpenseDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MajorExpenseDetailsView(
                majorExpense: MajorExpense(
                    id: 1,
                    name: "Car Repair",
                    category: .vehicle,
                    date: Date(),
                    amount: 15000.0,
                    notes: "Engine repair and maintenance",
                    userId: "preview-user"
                ),
                repoService: SupabaseTransactionRepoService(transactionType: .majorExpense)
            )
        }
    }
}
