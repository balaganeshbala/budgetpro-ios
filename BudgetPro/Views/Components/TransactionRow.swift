import SwiftUI

// MARK: - Generic Transaction Row
struct TransactionRow<T, Destination: View>: View {
    let title: String
    let amount: Double
    let dateString: String
    let categoryIcon: String
    let categoryColor: Color?
    let iconShape: IconShape
    let amountColor: Color
    let showChevron: Bool
    let destination: () -> Destination
    
    enum IconShape {
        case circle
        case roundedRectangle
    }
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 10) {
                // Category icon with dynamic shape and gradient
                Group {
                    switch iconShape {
                    case .circle:
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        (categoryColor ?? Color.primary).opacity(0.3),
                                        (categoryColor ?? Color.primary).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                    case .roundedRectangle:
                        RoundedRectangle(cornerRadius: 10, style: .circular)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        (categoryColor ?? Color.primary).opacity(0.3),
                                        (categoryColor ?? Color.primary).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                    }
                }
                .overlay(
                    Image(systemName: categoryIcon)
                        .foregroundStyle(
                            .linearGradient(colors: [categoryColor ?? Color.primary, (categoryColor ?? Color.primary).opacity(0.5)], startPoint: .top, endPoint: .bottomTrailing)
                        )
                        .font(.system(size: 16, weight: .bold))
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.appFont(14, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text(dateString)
                        .font(.appFont(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(formatAmount(amount))")
                    .font(.appFont(14, weight: .semibold))
                    .foregroundColor(amountColor)
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.appFont(14, weight: .semibold))
                        .foregroundStyle(Color.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
