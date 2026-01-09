//
//  LockTimeout.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/01/26.
//

import Foundation

enum LockTimeout: String, CaseIterable, Identifiable, Codable {
    case immediately = "Immediately"
    case fiveSeconds = "After 5 seconds"
    case thirtySeconds = "After 30 seconds"
    case oneMinute = "After 1 minute"
    
    var id: String { rawValue }
    
    var timeInterval: TimeInterval {
        switch self {
        case .immediately: return 0
        case .fiveSeconds: return 5
        case .thirtySeconds: return 30
        case .oneMinute: return 60
        }
    }
}
