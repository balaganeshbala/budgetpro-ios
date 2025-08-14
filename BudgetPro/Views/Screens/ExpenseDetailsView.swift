import SwiftUI

struct ExpenseDetailsView: View {
    @StateObject private var viewModel: ExpenseDetailsViewModel
    let expense: Expense
    
    init(expense: Expense) {
        self.expense = expense
        self._viewModel = StateObject(wrappedValue: ExpenseDetailsViewModel(expense: expense))
    }
    
    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            transactionType: .expense,
            mode: .update,
            categories: ExpenseCategory.userSelectableCategories,
            selectedCategory: viewModel.selectedCategory,
            onCategorySelected: { category in
                viewModel.selectedCategory = category
            }
        )
    }
}



struct ExpenseDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseDetailsView(
            expense: Expense(
                id: 1,
                name: "Lunch",
                amount: 250.0,
                category: "Food",
                date: Date(),
                categoryIcon: "fork.knife",
                categoryColor: .orange
            )
        )
    }
}
