import SwiftUI

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

struct Subscription: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Double
    var billingCycle: BillingCycle
    var startDate: Date
    var notes: String?
    var colorHex: String
    
    // Computed property for easy Color access
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // Calculate the next renewal date based on start date and billing cycle
    var nextRenewalDate: Date {
        let calendar = Calendar.current
        let today = Date()
        
        // If start date is in the future, that's the renewal date
        if startDate > today {
            return startDate
        }
        
        // Find next date
        var component = DateComponents()
        switch billingCycle {
        case .weekly: component.day = 7
        case .monthly: component.month = 1
        case .yearly: component.year = 1
        }
        
        // Simple logic: keep adding cycle until we pass today
        // Optimisation: Could use math to jump, but iteration is safe for reasonable dates
        var nextDate = startDate
        while nextDate <= today {
            if let date = calendar.date(byAdding: component, to: nextDate) {
                nextDate = date
            } else {
                break
            }
        }
        return nextDate
    }
    
    var monthlyEquivalentAmount: Double {
        switch billingCycle {
        case .weekly: return amount * 4.33
        case .monthly: return amount
        case .yearly: return amount / 12.0
        }
    }
    
    init(id: UUID = UUID(), name: String, amount: Double, billingCycle: BillingCycle, startDate: Date, notes: String? = nil, colorHex: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.notes = notes
        self.colorHex = colorHex
    }
}
