import SwiftUI

enum ExpenseCategory: String, CaseIterable {
    case emi = "EMI"
    case food = "Food"
    case holidayTrip = "Holiday/Trip"
    case housing = "Housing"
    case shopping = "Shopping"
    case travel = "Travel"
    case family = "Family"
    case chargesFees = "Charges/Fees"
    case groceries = "Groceries"
    case healthBeauty = "Health/Beauty"
    case entertainment = "Entertainment"
    case charityGift = "Charity/Gift"
    case education = "Education"
    case vehicle = "Vehicle"
    case unknown = "Unknown"
    
    var displayName: String {
        return self.rawValue
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
        case .education: return Color(red: 0.2, green: 0.6, blue: 0.5)
        case .vehicle: return .gray
        case .unknown: return .secondary
        }
    }
    
    static func from(categoryName: String) -> ExpenseCategory {
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