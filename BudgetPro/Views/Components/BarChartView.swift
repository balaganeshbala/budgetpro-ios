//
//  BarChartView.swift
//  BudgetPro
//
//  Created by Xyne on 20/08/25.
//

import SwiftUI

// MARK: - Bar Chart Data Model
struct BarChartData {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    let icon: String?
    
    init(label: String, value: Double, color: Color, icon: String? = nil) {
        self.label = label
        self.value = value
        self.color = color
        self.icon = icon
    }
}

// MARK: - Bar Chart View
struct BarChartView: View {
    let data: [BarChartData]
    let title: String
    let showValues: Bool
    let chartHeight: CGFloat
    let orientation: ChartOrientation
    
    enum ChartOrientation {
        case vertical
        case horizontal
    }
    
    init(
        data: [BarChartData],
        title: String = "Distribution",
        showValues: Bool = true,
        chartHeight: CGFloat = 200,
        orientation: ChartOrientation = .vertical
    ) {
        self.data = data
        self.title = title
        self.showValues = showValues
        self.chartHeight = chartHeight
        self.orientation = orientation
    }
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(title)
                .font(.appFont(18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            if !data.isEmpty {
                switch orientation {
                case .vertical:
                    verticalBarChart
                case .horizontal:
                    horizontalBarChart
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.appFont(40))
                        .foregroundColor(.secondaryText)
                    
                    Text("No data available")
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                .frame(height: chartHeight)
            }
        }
    }
    
    // MARK: - Vertical Bar Chart
    private var verticalBarChart: some View {
        VStack(spacing: 16) {
            // Chart
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 8) {
                        // Value label
                        if showValues {
                            Text("₹\(CommonHelpers.formatAmount(item.value))")
                                .font(.appFont(14, weight: .regular))
                                .foregroundColor(item.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        item.color,
                                        item.color.opacity(0.7)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: max(30, (UIScreen.main.bounds.width - 200) / CGFloat(data.count) - 12),
                                height: maxValue > 0 ? CGFloat(item.value / maxValue) * chartHeight : 0
                            )
                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: item.value)
                        
                        // Label
                        VStack(spacing: 4) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.appFont(12, weight: .medium))
                                    .foregroundColor(item.color)
                            }
                            
                            Text(item.label)
                                .font(.appFont(14, weight: .regular))
                                .foregroundColor(.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(width: max(30, (UIScreen.main.bounds.width - 80) / CGFloat(data.count) - 12))
                    }
                }
            }
            .frame(height: chartHeight + 60) // Extra space for labels
        }
    }
    
    // MARK: - Horizontal Bar Chart
    private var horizontalBarChart: some View {
        VStack(spacing: 16) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    // Label with icon
                    HStack(spacing: 8) {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.appFont(14))
                                .foregroundColor(item.color)
                                .frame(width: 20)
                        }
                        
                        Text(item.label)
                            .font(.appFont(13, weight: .medium))
                            .foregroundColor(.primaryText)
                            .frame(width: 80, alignment: .leading)
                            .lineLimit(1)
                    }
                    .frame(width: 120, alignment: .leading)
                    
                    // Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 24)
                            
                            // Filled bar
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            item.color,
                                            item.color.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: maxValue > 0 ? geometry.size.width * CGFloat(item.value / maxValue) : 0,
                                    height: 24
                                )
                                .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: item.value)
                        }
                    }
                    .frame(height: 24)
                    
                    // Value
                    if showValues {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("₹\(CommonHelpers.formatAmount(item.value))")
                                .font(.appFont(12, weight: .semibold))
                                .foregroundColor(item.color)
                        }
                        .frame(width: 80, alignment: .trailing)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Expense & Income Bar Chart
struct ExpenseIncomeBarChart: View {
    let totalExpenses: Double
    let totalIncome: Double
    
    private var barChartData: [BarChartData] {
        var data: [BarChartData] = []
        
        if totalIncome > 0 {
            data.append(BarChartData(
                label: "Income",
                value: totalIncome,
                color: .primary
            ))
        }
        
        if totalExpenses > 0 {
            data.append(BarChartData(
                label: "Expenses",
                value: totalExpenses,
                color: .secondary
            ))
        }
        
        return data
    }
    
    var body: some View {
        BarChartView(
            data: barChartData,
            title: "Income vs Expenses",
            showValues: true,
            chartHeight: 150,
            orientation: .vertical
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Expense Categories Bar Chart
struct ExpenseCategoriesBarChart: View {
    let expenses: [Expense]
    
    private var categoryData: [BarChartData] {
        let groupedExpenses = Dictionary(grouping: expenses) { $0.category }
        
        return groupedExpenses.compactMap { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            
            return BarChartData(
                label: category.displayName,
                value: total,
                color: category.color,
                icon: category.iconName
            )
        }.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        BarChartView(
            data: categoryData,
            title: "Expenses by Category",
            showValues: true,
            chartHeight: 180,
            orientation: .horizontal
        )
    }
}

// MARK: - Preview
struct BarChartView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView {
                VStack(spacing: 30) {
                    CardView {
                        ExpenseIncomeBarChart(
                            totalExpenses: 45643,
                            totalIncome: 85600
                        )
                    }
                    
                    CardView {
                        ExpenseCategoriesBarChart(expenses: sampleExpenses)
                    }
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            ScrollView {
                VStack(spacing: 30) {
                    CardView {
                        ExpenseIncomeBarChart(
                            totalExpenses: 45643,
                            totalIncome: 85600
                        )
                    }
                    
                    CardView {
                        ExpenseCategoriesBarChart(expenses: sampleExpenses)
                    }
                }
                .padding()
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
            date: Date()
        ),
        Expense(
            id: 2,
            name: "Fuel",
            amount: 4000,
            category: .travel,
            date: Date()
        ),
        Expense(
            id: 3,
            name: "Movie Tickets",
            amount: 3000,
            category: .entertainment,
            date: Date()
        ),
        Expense(
            id: 4,
            name: "Shopping",
            amount: 8000,
            category: .shopping,
            date: Date()
        )
    ]
    
    static let sampleIncomes: [Income] = [
        Income(
            id: 1,
            source: "Salary",
            amount: 60000,
            category: .salary,
            date: Date()
        ),
        Income(
            id: 2,
            source: "Freelance",
            amount: 15000,
            category: .sideHustle,
            date: Date()
        )
    ]
}
