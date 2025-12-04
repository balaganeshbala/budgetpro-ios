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
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 10) {
                
                RowItemIcon(categoryIcon: categoryIcon, iconShape: iconShape)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.appFont(14, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text(dateString)
                        .font(.appFont(12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("₹\(CommonHelpers.formatAmount(amount))")
                    .font(.appFont(14, weight: .semibold))
                    .foregroundColor(amountColor)
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.appFont(14, weight: .regular))
                        .foregroundStyle(Color.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                List {
                    Section(header: Text("Rounded Rectangle")) {
                        TransactionRow<Void, Text>(
                            title: "Groceries",
                            amount: 2350,
                            dateString: "12 Jul 2025",
                            categoryIcon: "cart.fill",
                            categoryColor: .green,
                            iconShape: .roundedRectangle,
                            amountColor: .primaryText,
                            showChevron: true
                        ) {
                            Text("Detail")
                        }
                        
                        TransactionRow<Void, Text>(
                            title: "Fuel",
                            amount: 1200,
                            dateString: "10 Jul 2025",
                            categoryIcon: "fuelpump.fill",
                            categoryColor: .orange,
                            iconShape: .roundedRectangle,
                            amountColor: .primaryText,
                            showChevron: false
                        ) {
                            Text("Detail")
                        }
                    }
                    
                    Section(header: Text("Circle")) {
                        TransactionRow<Void, Text>(
                            title: "Salary",
                            amount: 60000,
                            dateString: "01 Jul 2025",
                            categoryIcon: "indianrupeesign.circle.fill",
                            categoryColor: .blue,
                            iconShape: .circle,
                            amountColor: .primaryText,
                            showChevron: true
                        ) {
                            Text("Detail")
                        }
                        
                        TransactionRow<Void, Text>(
                            title: "Freelance",
                            amount: 15000,
                            dateString: "08 Jul 2025",
                            categoryIcon: "briefcase.fill",
                            categoryColor: .purple,
                            iconShape: .circle,
                            amountColor: .primaryText,
                            showChevron: false
                        ) {
                            Text("Detail")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("TransactionRow")
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            NavigationView {
                List {
                    Section(header: Text("Rounded Rectangle")) {
                        TransactionRow<Void, Text>(
                            title: "Groceries",
                            amount: 2350,
                            dateString: "12 Jul 2025",
                            categoryIcon: "cart.fill",
                            categoryColor: .green,
                            iconShape: .roundedRectangle,
                            amountColor: .primaryText,
                            showChevron: true
                        ) {
                            Text("Detail")
                        }
                        
                        TransactionRow<Void, Text>(
                            title: "Fuel",
                            amount: 1200,
                            dateString: "10 Jul 2025",
                            categoryIcon: "fuelpump.fill",
                            categoryColor: .orange,
                            iconShape: .roundedRectangle,
                            amountColor: .primaryText,
                            showChevron: false
                        ) {
                            Text("Detail")
                        }
                    }
                    
                    Section(header: Text("Circle")) {
                        TransactionRow<Void, Text>(
                            title: "Salary",
                            amount: 60000,
                            dateString: "01 Jul 2025",
                            categoryIcon: "indianrupeesign.circle.fill",
                            categoryColor: .blue,
                            iconShape: .circle,
                            amountColor: .primaryText,
                            showChevron: true
                        ) {
                            Text("Detail")
                        }
                        
                        TransactionRow<Void, Text>(
                            title: "Freelance",
                            amount: 15000,
                            dateString: "08 Jul 2025",
                            categoryIcon: "briefcase.fill",
                            categoryColor: .purple,
                            iconShape: .circle,
                            amountColor: .primaryText,
                            showChevron: false
                        ) {
                            Text("Detail")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("TransactionRow")
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
