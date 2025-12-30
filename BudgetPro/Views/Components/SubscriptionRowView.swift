import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            RowItemIcon(
                categoryIcon: "arrow.triangle.2.circlepath", // Generic recurring icon
                iconShape: .roundedRectangle,
                iconColor: subscription.color,
                backgroundColor: subscription.color.opacity(0.1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.appFont(16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(subscription.billingCycle.displayName) • Renewal: \(formatDate(subscription.nextRenewalDate))")
                    .font(.appFont(12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("₹\(CommonHelpers.formatAmount(subscription.amount))")
                .font(.appFont(16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}
