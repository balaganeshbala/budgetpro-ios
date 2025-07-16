import Foundation
import SwiftUI

struct Expense: Identifiable {
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
}