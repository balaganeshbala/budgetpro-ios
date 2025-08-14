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
        case .travel: return "car.fill"
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
        case .emi: return .purple
        case .food: return .orange
        case .holidayTrip: return .cyan
        case .housing: return .brown
        case .shopping: return .pink
        case .travel: return .blue
        case .family: return .green
        case .chargesFees: return .yellow
        case .groceries: return .mint
        case .healthBeauty: return .red
        case .entertainment: return .indigo
        case .charityGift: return .teal
        case .education: return .indigo
        case .vehicle: return .gray
        case .unknown: return .secondary
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
