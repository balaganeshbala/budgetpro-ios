import Foundation
import SwiftUI

struct Expense: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let userId: String
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case amount
        case category
        case date
        case userId = "user_id"
    }
    
    init(id: Int, name: String, amount: Double, category: ExpenseCategory, date: Date, userId: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        userId = try container.decode(String.self, forKey: .userId)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        category = ExpenseCategory.from(categoryName: categoryString)
        
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
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(userId, forKey: .userId)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        try container.encode(dateStr, forKey: .date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(amount)
        hasher.combine(category)
        hasher.combine(userId)
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.amount == rhs.amount &&
               lhs.category == rhs.category &&
               lhs.date == rhs.date &&
               lhs.userId == rhs.userId
    }
}

struct MajorExpense: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let category: MajorExpenseCategory
    let date: Date
    let amount: Double
    let notes: String?
    let userId: String
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case date
        case amount
        case notes
        case userId = "user_id"
    }
    
    init(id: Int, name: String, category: MajorExpenseCategory, date: Date, amount: Double, notes: String?, userId: String) {
        self.id = id
        self.name = name
        self.category = category
        self.date = date
        self.amount = amount
        self.notes = notes
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        userId = try container.decode(String.self, forKey: .userId)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        category = MajorExpenseCategory.from(categoryName: categoryString)
        
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
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(notes, forKey: .notes)
        try container.encode(userId, forKey: .userId)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        try container.encode(dateStr, forKey: .date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(category)
        hasher.combine(date)
        hasher.combine(amount)
        hasher.combine(notes)
        hasher.combine(userId)
    }
    
    static func == (lhs: MajorExpense, rhs: MajorExpense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.category == rhs.category &&
               lhs.date == rhs.date &&
               lhs.amount == rhs.amount &&
               lhs.notes == rhs.notes &&
               lhs.userId == rhs.userId
    }
}

// MARK: - Insert DTOs
struct ExpenseInsertData: Codable {
    let name: String
    let amount: Double
    let category: String
    let date: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case category
        case date
        case userId = "user_id"
    }
}

struct MajorExpenseInsertData: Codable {
    let name: String
    let amount: Double
    let category: String
    let date: String
    let notes: String?
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case category
        case date
        case notes
        case userId = "user_id"
    }
}
