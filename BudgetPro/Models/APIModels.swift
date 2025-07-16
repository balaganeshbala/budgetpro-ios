import Foundation

struct BudgetResponse: Codable {
    let id: Int
    let category: String
    let amount: Double
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case amount
        case date
        case userId = "user_id"
    }
}

struct ExpenseResponse: Codable {
    let id: Int
    let date: String
    let name: String
    let category: String
    let amount: Double
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case name
        case category
        case amount
        case userId = "user_id"
    }
}

struct IncomeResponse: Codable {
    let id: Int
    let source: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case source
        case amount
        case category
        case date
        case userId = "user_id"
    }
}