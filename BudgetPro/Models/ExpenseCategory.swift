import SwiftUI

enum ExpenseCategory: String, CaseIterable, CategoryProtocol {
    case emi
    case food
    case holidayTrip
    case housing
    case shopping
    case travel
    case family
    case chargesFees
    case groceries
    case healthBeauty
    case entertainment
    case charityGift
    case education
    case vehicle
    case unknown
    
    /// Returns all categories except 'unknown' for user-facing selections
    static var userSelectableCategories: [ExpenseCategory] {
        return allCases.filter { $0 != .unknown }
    }
    
    var displayName: String {
        switch self {
        case .emi: return "EMI"
        case .food: return "Food"
        case .holidayTrip: return "Holiday/Trip"
        case .housing: return "Housing"
        case .shopping: return "Shopping"
        case .travel: return "Travel"
        case .family: return "Family"
        case .chargesFees: return "Charges/Fees"
        case .groceries: return "Groceries"
        case .healthBeauty: return "Health/Beauty"
        case .entertainment: return "Entertainment"
        case .charityGift: return "Charity/Gift"
        case .education: return "Education"
        case .vehicle: return "Vehicle"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .emi: return "creditcard.and.123"
        case .food: return "fork.knife"
        case .holidayTrip: return "airplane"
        case .housing: return "house.fill"
        case .shopping: return "bag.fill"
        case .travel: return "bus.fill"
        case .family: return "person.3.fill"
        case .chargesFees: return "dollarsign.circle"
        case .groceries: return "cart.fill"
        case .healthBeauty: return "heart.fill"
        case .entertainment: return "tv"
        case .charityGift: return "gift.fill"
        case .education: return "book.fill"
        case .vehicle: return "car"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .emi: return .red
        case .food: return .orange
        case .holidayTrip: return .yellow
        case .housing: return .green
        case .shopping: return .mint
        case .travel: return .cyan
        case .family: return .blue
        case .chargesFees: return .indigo
        case .groceries: return .purple
        case .healthBeauty: return .pink
        case .entertainment: return .teal
        case .charityGift: return Color(.systemPink)
        case .education: return Color(.systemPurple)
        case .vehicle: return Color(.systemOrange)
        case .unknown: return Color(.systemGray)
        }
    }
    
    static func from(categoryName: String) -> ExpenseCategory {
        // First try to match exact rawValue (new format)
        if let category = ExpenseCategory(rawValue: categoryName) {
            return category
        }
        
        // Fall back to displayName matching (for backward compatibility)
        let lowercased = categoryName.lowercased()
        
        switch lowercased {
        case "emi": return .emi
        case "food": return .food
        case "holiday/trip", "holiday", "trip": return .holidayTrip
        case "housing", "rent": return .housing
        case "shopping": return .shopping
        case "travel", "transport": return .travel
        case "family": return .family
        case "home": return .family
        case "charges/fees", "charges", "fees", "utilities": return .chargesFees
        case "groceries": return .groceries
        case "health/beauty", "health", "beauty", "personal care": return .healthBeauty
        case "entertainment": return .entertainment
        case "charity/gift", "charity", "gift": return .charityGift
        case "education": return .education
        case "vehicle": return .vehicle
        default: return .unknown
        }
    }
}

enum MajorExpenseCategory: String, CaseIterable, CategoryProtocol {
    case vehicle
    case homeRenovation
    case medical
    case education
    case appliances
    case electronics
    case furniture
    case event
    case travel
    case legal
    case disasterRecovery
    case relocation
    case family
    case gift
    case taxes
    case debtSettlement
    case donation
    case other
    
    var displayName: String {
        switch self {
        case .vehicle: return "Vehicle"
        case .homeRenovation: return "Home Renovation"
        case .medical: return "Medical"
        case .education: return "Education"
        case .appliances: return "Appliances"
        case .electronics: return "Electronics"
        case .furniture: return "Furniture"
        case .event: return "Event"
        case .travel: return "Travel"
        case .legal: return "Legal"
        case .disasterRecovery: return "Disaster Recovery"
        case .relocation: return "Relocation"
        case .family: return "Family"
        case .gift: return "Gift"
        case .taxes: return "Taxes"
        case .debtSettlement: return "Debt Settlement"
        case .donation: return "Donation"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .vehicle: return "car.fill"
        case .homeRenovation: return "hammer.fill"
        case .medical: return "cross.fill"
        case .education: return "graduationcap.fill"
        case .appliances: return "washer.fill"
        case .electronics: return "tv.fill"
        case .furniture: return "bed.double.fill"
        case .event: return "party.popper.fill"
        case .travel: return "airplane.departure"
        case .legal: return "scale.3d"
        case .disasterRecovery: return "exclamationmark.triangle.fill"
        case .relocation: return "house.and.flag.fill"
        case .family: return "person.3.fill"
        case .gift: return "gift.fill"
        case .taxes: return "doc.text.fill"
        case .debtSettlement: return "creditcard.trianglebadge.exclamationmark"
        case .donation: return "heart.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .vehicle: return Color(.systemOrange)
        case .homeRenovation: return Color(.systemBrown)
        case .medical: return .red
        case .education: return Color(.systemPurple)
        case .appliances: return .gray
        case .electronics: return .blue
        case .furniture: return Color(.systemBrown)
        case .event: return .pink
        case .travel: return .cyan
        case .legal: return Color(.systemIndigo)
        case .disasterRecovery: return Color(.systemRed)
        case .relocation: return .green
        case .family: return Color(.systemBlue)
        case .gift: return Color(.systemPink)
        case .taxes: return Color(.systemYellow)
        case .debtSettlement: return Color(.systemRed)
        case .donation: return Color(.systemGreen)
        case .other: return Color(.systemGray)
        }
    }
    
    static func from(categoryName: String) -> MajorExpenseCategory {
        // First try to match exact rawValue
        if let category = MajorExpenseCategory(rawValue: categoryName) {
            return category
        }
        
        // Fall back to displayName matching (for backward compatibility)
        let lowercased = categoryName.lowercased()
        
        switch lowercased {
        case "vehicle", "car", "auto": return .vehicle
        case "home renovation", "renovation", "home improvement": return .homeRenovation
        case "medical", "health", "healthcare": return .medical
        case "education", "school", "college", "university": return .education
        case "appliances", "appliance": return .appliances
        case "electronics", "electronic", "gadgets": return .electronics
        case "furniture": return .furniture
        case "event", "party", "celebration": return .event
        case "travel", "trip", "vacation": return .travel
        case "legal", "lawyer", "attorney": return .legal
        case "disaster recovery", "disaster", "emergency": return .disasterRecovery
        case "relocation", "moving", "move": return .relocation
        case "family": return .family
        case "gift", "present": return .gift
        case "taxes", "tax": return .taxes
        case "debt settlement", "debt": return .debtSettlement
        case "donation", "charity": return .donation
        default: return .other
        }
    }
}
