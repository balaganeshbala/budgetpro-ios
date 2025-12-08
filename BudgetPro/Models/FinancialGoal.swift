//
//  FinancialGoal.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import Foundation

enum FinancialGoalStatus : String, CaseIterable, Codable, Hashable {
    case active, paused, completed
}

struct FinancialGoal: Identifiable, Codable, Hashable {
    let id: UUID          // Maps to goal_id
    let userId: UUID      // Maps to user_id
    var title: String
    var colorHex: String
    var targetAmount: Double
    var targetDate: Date
    var status: FinancialGoalStatus // "active", "paused", "completed"
    
    var contributions: [GoalContribution]?
    
    enum CodingKeys: String, CodingKey {
        case id = "goal_id"
        case userId = "user_id"
        case title
        case colorHex = "color_hex"
        case targetAmount = "target_amount"
        case targetDate = "target_date"
        case status
        case contributions
    }

    
    init(id: UUID, userId: UUID, title: String, colorHex: String, targetAmount: Double, targetDate: Date, status: FinancialGoalStatus, contributions: [GoalContribution]? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.colorHex = colorHex
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.status = status
        self.contributions = contributions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        targetAmount = try container.decode(Double.self, forKey: .targetAmount)
        status = try container.decode(FinancialGoalStatus.self, forKey: .status)
        contributions = try container.decodeIfPresent([GoalContribution].self, forKey: .contributions)
        
        let dateString = try container.decode(String.self, forKey: .targetDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Try yyyy-MM-dd first
        if let date = formatter.date(from: dateString) {
            targetDate = date
        } else {
            // Fallback to ISO8601
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                targetDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .targetDate, in: container, debugDescription: "Invalid date format: \(dateString)")
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(status, forKey: .status)
        // contributions are read-only (joined) from Supabase and should not be sent back during insert/update
        // try container.encodeIfPresent(contributions, forKey: .contributions)
        
        // Encode date as yyyy-MM-dd for Supabase DATE column consistency
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: targetDate)
        try container.encode(dateString, forKey: .targetDate)
    }
}
