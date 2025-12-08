//
//  GoalContribution.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//


import Foundation

struct GoalContribution: Identifiable, Codable, Hashable {
    let id: Int?
    let goalId: UUID
    let amount: Decimal
    let transactionDate: Date
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case goalId = "goal_id"
        case amount
        case transactionDate = "date"
        case note
    }
    
    init(id: Int?, goalId: UUID, amount: Decimal, transactionDate: Date, note: String?) {
        self.id = id
        self.goalId = goalId
        self.amount = amount
        self.transactionDate = transactionDate
        self.note = note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        goalId = try container.decode(UUID.self, forKey: .goalId)
        amount = try container.decode(Decimal.self, forKey: .amount)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        
        let dateString = try container.decode(String.self, forKey: .transactionDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            transactionDate = date
        } else {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                transactionDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .transactionDate, in: container, debugDescription: "Invalid date format: \(dateString)")
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(goalId, forKey: .goalId)
        try container.encode(amount, forKey: .amount)
        try container.encode(note, forKey: .note)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: transactionDate)
        try container.encode(dateString, forKey: .transactionDate)
    }
}
