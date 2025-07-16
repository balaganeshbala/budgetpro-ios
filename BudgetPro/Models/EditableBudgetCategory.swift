import Foundation

struct EditableBudgetCategory: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    var amount: Double
}