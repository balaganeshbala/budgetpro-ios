import Foundation

struct FinancialMonthlySummary: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let year: Int
    let month: Int
    let totalAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case year
        case month
        case totalAmount = "total_amount"
    }
}
