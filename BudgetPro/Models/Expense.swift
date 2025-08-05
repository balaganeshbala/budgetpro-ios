import Foundation
import SwiftUI

struct Expense: Identifiable, Hashable {
    let id: Int
    let name: String
    let amount: Double
    let category: String
    let date: Date
    let categoryIcon: String
    let categoryColor: Color
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(amount)
        hasher.combine(category)
        hasher.combine(date)
        hasher.combine(categoryIcon)
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.amount == rhs.amount &&
               lhs.category == rhs.category &&
               lhs.date == rhs.date &&
               lhs.categoryIcon == rhs.categoryIcon
    }
}