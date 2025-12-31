import Foundation

struct Income: Identifiable, Hashable, Codable {
    let id: Int
    let source: String
    let amount: Double
    let category: IncomeCategory
    let date: Date
    let userId: String
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case source
        case amount
        case category
        case date
        case userId = "user_id"
    }
    
    init(id: Int, source: String, amount: Double, category: IncomeCategory, date: Date, userId: String) {
        self.id = id
        self.source = source
        self.amount = amount
        self.category = category
        self.date = date
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        source = try container.decode(String.self, forKey: .source)
        amount = try container.decode(Double.self, forKey: .amount)
        userId = try container.decode(String.self, forKey: .userId)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        category = IncomeCategory.from(categoryName: categoryString)
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateValue = formatter.date(from: dateString) {
            date = dateValue
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string does not match format yyyy-MM-dd")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(source, forKey: .source)
        try container.encode(amount, forKey: .amount)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(userId, forKey: .userId)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        try container.encode(dateStr, forKey: .date)
    }
}

// MARK: - Insert DTOs
struct IncomeInsertData: Codable {
    let source: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case source
        case amount
        case category
        case date
        case userId = "user_id"
    }
}
