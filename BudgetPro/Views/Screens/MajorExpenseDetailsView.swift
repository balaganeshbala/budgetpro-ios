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
    
    init(majorExpense: MajorExpense) {
        self.majorExpense = majorExpense
        // For now, construct the service here. You can move this to a DI container later.
        let service = SupabaseTransactionRepoService(transactionType: .majorExpense)
        self._viewModel = StateObject(wrappedValue: MajorExpenseDetailsViewModel(majorExpense: majorExpense, repoService: service))
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
                    notes: "Engine repair and maintenance"
                )
            )
        }
    }
}
