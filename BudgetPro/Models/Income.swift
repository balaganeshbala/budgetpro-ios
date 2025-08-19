import Foundation

struct Income: Identifiable, Hashable {
    let id: Int
    let source: String
    let amount: Double
    let category: IncomeCategory
    let date: Date
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}
