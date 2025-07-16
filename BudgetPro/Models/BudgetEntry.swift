import Foundation

struct BudgetEntry: Codable {
    let date: String
    let category: String
    let amount: Double
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case date
        case category
        case amount
        case userId = "user_id"
    }
}