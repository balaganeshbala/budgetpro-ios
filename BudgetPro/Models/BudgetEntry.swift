import Foundation

struct BudgetEntry: Codable, Identifiable {
    let id: Int?
    let date: String
    let category: String
    let amount: Double
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case category
        case amount
        case userId = "user_id"
    }
    
    init(id: Int? = nil, date: String, category: String, amount: Double, userId: String) {
        self.id = id
        self.date = date
        self.category = category
        self.amount = amount
        self.userId = userId
    }
}


