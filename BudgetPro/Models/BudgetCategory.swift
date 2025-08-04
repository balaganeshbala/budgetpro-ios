import Foundation

struct BudgetCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let budget: Double
    let spent: Double
}