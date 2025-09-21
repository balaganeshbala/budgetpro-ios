import Foundation
import SwiftUI

struct Expense: Identifiable, Hashable {
    let id: Int
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    
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
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.amount == rhs.amount &&
               lhs.category == rhs.category &&
               lhs.date == rhs.date
    }
}

struct MajorExpense: Identifiable, Hashable {
    let id: Int
    let name: String
    let category: MajorExpenseCategory
    let date: Date
    let amount: Double
    let notes: String?
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(category)
        hasher.combine(date)
        hasher.combine(amount)
        hasher.combine(notes)
    }
    
    static func == (lhs: MajorExpense, rhs: MajorExpense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.category == rhs.category &&
               lhs.date == rhs.date &&
               lhs.amount == rhs.amount &&
               lhs.notes == rhs.notes
    }
}
