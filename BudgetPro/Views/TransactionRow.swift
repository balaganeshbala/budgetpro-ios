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
                // Category icon with dynamic shape
                Group {
                    switch iconShape {
                    case .circle:
                        Circle()
                            .fill((categoryColor ?? Color.primary).opacity(0.2))
                            .frame(width: 40, height: 40)
                    case .roundedRectangle:
                        RoundedRectangle(cornerRadius: 10, style: .circular)
                            .fill((categoryColor ?? Color.primary).opacity(0.2))
                            .frame(width: 40, height: 40)
                    }
                }
                .overlay(
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor ?? Color.primary)
                        .font(.system(size: 16))
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.sora(14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(dateString)
                        .font(.sora(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(formatAmount(amount))")
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(amountColor)
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.sora(14, weight: .semibold))
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