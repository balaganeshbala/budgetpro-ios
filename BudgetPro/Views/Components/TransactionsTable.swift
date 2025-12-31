//
//  TransactionsTable.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/07/25.
//

import SwiftUI

struct TransactionsTable: View {
    let transactions: [Expense]
    
    @State private var sortColumnIndex = 0
    @State private var sortAscending = false
    @State private var sortedTransactions: [Expense] = []
    
    init(transactions: [Expense]) {
        self.transactions = transactions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if transactions.isEmpty {
                buildEmptyState()
            } else {
                buildTransactionList()
            }
        }
        .background(Color.cardBackground)
        .onAppear {
            sortedTransactions = transactions
            sortData()
        }
        .onChange(of: transactions) { newTransactions in
            sortedTransactions = newTransactions
            sortData()
        }
    }
    
    // MARK: - Empty State
    private func buildEmptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "receipt")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            
            Text("No transactions yet")
                .font(.appFont(16, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Transaction List
    private func buildTransactionList() -> some View {
        VStack(spacing: 0) {
            // Table Header
            buildTableHeader()
            
            // Divider
            Divider()
                .frame(height: 1)
                .background(Color.separator)
            
            // Table Body
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedTransactions.enumerated()), id: \.offset) { index, transaction in
                    VStack(spacing: 0) {
                        buildTransactionRow(transaction: transaction)
                        
                        if index < sortedTransactions.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.separator)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table Header
    private func buildTableHeader() -> some View {
        HStack {
            // Date column
            buildHeaderCell(
                title: "Date",
                flex: 2,
                onTap: { onSortColumn(0) },
                isActive: sortColumnIndex == 0,
                isAscending: sortAscending && sortColumnIndex == 0,
                alignment: .leading
            )
            
            // Description column
            buildHeaderCell(
                title: "Description",
                flex: 4,
                onTap: nil,
                isActive: false,
                isAscending: false,
                alignment: .leading
            )
            
            // Amount column
            buildHeaderCell(
                title: "Amount",
                flex: 2,
                onTap: { onSortColumn(2) },
                isActive: sortColumnIndex == 2,
                isAscending: sortAscending && sortColumnIndex == 2,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.cardBackground)
    }
    
    // MARK: - Header Cell
    private func buildHeaderCell(
        title: String,
        flex: Int,
        onTap: (() -> Void)?,
        isActive: Bool,
        isAscending: Bool,
        alignment: HorizontalAlignment
    ) -> some View {
        let content = HStack {
            if alignment == .trailing {
                Spacer()
            }
            
            Text(title)
                .font(.appFont(12, weight: isActive ? .bold : .semibold))
                .foregroundColor(isActive ? Color.primary : .secondaryText)
            
            if let _ = onTap, isActive {
                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color.primary)
            }
            
            if alignment == .leading {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        
        if let onTap = onTap {
            return AnyView(
                Button(action: onTap) {
                    content
                }
                .buttonStyle(PlainButtonStyle())
            )
        } else {
            return AnyView(content)
        }
    }
    
    // MARK: - Transaction Row
    private func buildTransactionRow(transaction: Expense) -> some View {
        Button(action: {
            // Optional: Handle transaction row tap if needed
        }) {
            HStack {
                // Date column
                Text(formatDate(transaction.date))
                    .font(.appFont(13, weight: .regular))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Description column
                Text(transaction.name)
                    .font(.appFont(13, weight: .regular))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Amount column
                Text(formatRupees(transaction.amount))
                    .font(.appFont(13, weight: .regular))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    private func sortData() {
        if sortColumnIndex == 0 {
            // Sort by date
            sortedTransactions.sort { a, b in
                return sortAscending ? a.date < b.date : a.date > b.date
            }
        } else if sortColumnIndex == 2 {
            // Sort by amount
            sortedTransactions.sort { a, b in
                return sortAscending ? a.amount < b.amount : a.amount > b.amount
            }
        }
    }
    
    private func onSortColumn(_ columnIndex: Int) {
        if sortColumnIndex == columnIndex {
            // Reverse the sort direction
            sortAscending.toggle()
        } else {
            // Sort by new column in descending order initially
            sortColumnIndex = columnIndex
            sortAscending = false
        }
        sortData()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
    
    private func formatRupees(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        if let formattedAmount = formatter.string(from: NSNumber(value: amount)) {
            return "₹\(formattedAmount)"
        }
        return "₹\(Int(amount))"
    }
}

// MARK: - Preview
struct TransactionsTable_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            VStack {
                TransactionsTable(transactions: [
                    Expense(
                        id: 1,
                        name: "Grocery Shopping",
                        amount: 2500,
                        category: .food,
                        date: Date(),
                        userId: "preview-user"
                    ),
                    Expense(
                        id: 2,
                        name: "Uber Ride",
                        amount: 350,
                        category: .travel,
                        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        userId: "preview-user"
                    ),
                    Expense(
                        id: 3,
                        name: "Movie Tickets",
                        amount: 800,
                        category: .entertainment,
                        date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                        userId: "preview-user"
                    )
                ])
                
                Spacer()
            }
            .background(Color.groupedBackground)
            .preferredColorScheme(.light)
            
            // Dark mode preview
            VStack {
                TransactionsTable(transactions: [
                    Expense(
                        id: 1,
                        name: "Grocery Shopping",
                        amount: 2500,
                        category: .food,
                        date: Date(),
                        userId: "preview-user"
                    ),
                    Expense(
                        id: 2,
                        name: "Uber Ride",
                        amount: 350,
                        category: .travel,
                        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        userId: "preview-user"
                    ),
                    Expense(
                        id: 3,
                        name: "Movie Tickets",
                        amount: 800,
                        category: .entertainment,
                        date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                        userId: "preview-user"
                    )
                ])
                
                Spacer()
            }
            .background(Color.groupedBackground)
            .preferredColorScheme(.dark)
        }
    }
}
