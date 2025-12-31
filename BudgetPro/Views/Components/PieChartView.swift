//
//  PieChartView.swift
//  BudgetPro
//
//  Created by Xyne on 20/08/25.
//

import SwiftUI

// MARK: - Pie Chart Data Model
struct PieChartData {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    
    init(label: String, value: Double, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Pie Chart View
struct PieChartView: View {
    let data: [PieChartData]
    let title: String
    let showLegend: Bool
    let chartSize: CGFloat
    
    init(
        data: [PieChartData],
        title: String = "Distribution",
        showLegend: Bool = true,
        chartSize: CGFloat = 200
    ) {
        self.data = data
        self.title = title
        self.showLegend = showLegend
        self.chartSize = chartSize
    }
    
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private var slices: [PieSlice] {
        var currentAngle: Double = -90 // Start from top
        var slices: [PieSlice] = []
        
        for item in data {
            let percentage = total > 0 ? item.value / total : 0
            let angle = percentage * 360
            
            slices.append(PieSlice(
                startAngle: currentAngle,
                endAngle: currentAngle + angle,
                color: item.color,
                percentage: percentage
            ))
            
            currentAngle += angle
        }
        
        return slices
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(title)
                .font(.appFont(18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            if total > 0 {
                VStack(spacing: 50) {
                    // Pie Chart
                    ZStack {
                        ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                            PieSliceView(slice: slice)
                                .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: slice.endAngle)
                        }
                    }
                    .frame(width: chartSize, height: chartSize)
                    
                    // Legend
                    if showLegend && !data.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                                LegendItem(
                                    data: item,
                                    percentage: total > 0 ? (item.value / total) * 100 : 0
                                )
                                .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: item.value)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.pie")
                        .font(.appFont(40))
                        .foregroundColor(.secondaryText)
                    
                    Text("No data available")
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                .frame(height: chartSize)
            }
        }
    }
}

// MARK: - Pie Slice Data Model
struct PieSlice {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let percentage: Double
}

// MARK: - Pie Slice View
struct PieSliceView: View {
    let slice: PieSlice
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 100
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(slice.startAngle),
                endAngle: .degrees(slice.endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(slice.color)
        .overlay(
            Path { path in
                let center = CGPoint(x: 100, y: 100)
                let radius: CGFloat = 100
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(slice.startAngle),
                    endAngle: .degrees(slice.endAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(Color.cardBackground, lineWidth: 2)
        )
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let data: PieChartData
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(data.color)
                .frame(width: 16, height: 16)
            
            HStack(spacing: 10) {
                Text(data.label)
                    .font(.appFont(13, weight: .medium))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.appFont(11))
                    .foregroundColor(.secondaryText)
            }
        }

    }
}

// MARK: - Expense & Income Pie Chart
struct ExpenseIncomePieChart: View {
    let expenses: [Expense]
    let incomes: [Income]
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    private var pieChartData: [PieChartData] {
        var data: [PieChartData] = []
        
        if totalIncome > 0 {
            data.append(PieChartData(
                label: "Income",
                value: totalIncome,
                color: .adaptiveGreen
            ))
        }
        
        if totalExpenses > 0 {
            data.append(PieChartData(
                label: "Expenses",
                value: totalExpenses,
                color: .adaptiveRed
            ))
        }
        
        return data
    }
    
    var body: some View {
        PieChartView(
            data: pieChartData,
            title: "Income vs Expenses",
            showLegend: true,
            chartSize: 180
        )
    }
}

// MARK: - Expense Categories Pie Chart
struct ExpenseCategoriesPieChart: View {
    let expenses: [Expense]
    
    private var categoryData: [PieChartData] {
        let groupedExpenses = Dictionary(grouping: expenses) { $0.category }
        
        return groupedExpenses.compactMap { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            
            return PieChartData(
                label: category.displayName,
                value: total,
                color: category.color
            )
        }.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        PieChartView(
            data: categoryData,
            title: "Expenses by Category",
            showLegend: true,
            chartSize: 180
        )
    }
}

// MARK: - Preview
struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView {
                CardView {
                    ExpenseIncomePieChart(
                        expenses: sampleExpenses,
                        incomes: sampleIncomes
                    )
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            ScrollView {
                CardView {
                    ExpenseIncomePieChart(
                        expenses: sampleExpenses,
                        incomes: sampleIncomes
                    )
                }
            }
            .background(Color.groupedBackground)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
    
    // Sample data for preview
    static let sampleExpenses: [Expense] = [
        Expense(
            id: 1,
            name: "Groceries",
            amount: 5000,
            category: .groceries,
            date: Date(),
            userId: "preview-user"
        ),
        Expense(
            id: 2,
            name: "Fuel",
            amount: 4000,
            category: .travel,
            date: Date(),
            userId: "preview-user"
        ),
        Expense(
            id: 3,
            name: "Movie Tickets",
            amount: 3000,
            category: .entertainment,
            date: Date(),
            userId: "preview-user"
        ),
        Expense(
            id: 4,
            name: "Shopping",
            amount: 8000,
            category: .shopping,
            date: Date(),
            userId: "preview-user"
        )
    ]
    
    static let sampleIncomes: [Income] = [
        Income(
            id: 1,
            source: "Salary",
            amount: 60000,
            category: .salary,
            date: Date(),
            userId: "preview-user"
        ),
        Income(
            id: 2,
            source: "Freelance",
            amount: 15000,
            category: .sideHustle,
            date: Date(),
            userId: "preview-user"
        )
    ]
}
