//
//  MonthlyTrendsView.swift
//  BudgetPro
//
//  Created by Antigravity on 06/01/26.
//

import SwiftUI

struct MonthlyTrendsView: View {
    @StateObject private var viewModel: MonthlyTrendsViewModel
    
    init(userId: String, repoService: DataFetchRepoService) {
        _viewModel = StateObject(wrappedValue: MonthlyTrendsViewModel(userId: userId, repoService: repoService))
    }
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxHeight: .infinity)
                } else if viewModel.trendData.isEmpty {
                    EmptyDataIndicatorView(icon: "chart.xyaxis.line",
                                           title: "No Data Available",
                                           bodyText: "Add some expenses and income to see your trends")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Chart Mode Selector
                            chartModeSelector
                            
                            // Charts
                            chartSection
                            
                            // Summary Stats
                            summaryStatsSection
                        }
                        .padding()
                        .padding( .bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("Monthly Trends")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchAllData()
            }
        }
    }
    
    
    // MARK: - Chart Mode Selector
    @State private var selectedChartMode: ChartMode = .expense
    
    enum ChartMode: String, CaseIterable, Identifiable {
        case income = "Income"
        case expense = "Expense"
        case savings = "Savings"
        var id: String { rawValue }
    }
    
    private var chartModeSelector: some View {
        Picker("Chart Mode", selection: $selectedChartMode) {
            ForEach(ChartMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "\(selectedChartMode.rawValue) Trend", subtitle: "Last Two Years")
                
                if !viewModel.trendData.isEmpty {
                    TrendLineChart(data: viewModel.trendData, mode: selectedChartMode)
                        .frame(height: 220)
                        .padding(.top, 10)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Summary Stats
    private var summaryStatsSection: some View {
        // Calculate Averages - Ignoring 0s
        let incomeMonths = viewModel.trendData.filter { $0.totalIncome > 0 }
        let expenseMonths = viewModel.trendData.filter { $0.totalExpense > 0 }
        let savingsMonths = viewModel.trendData.filter { $0.savings > 0 }
        
        let avgIncome = incomeMonths.isEmpty ? 0 : incomeMonths.reduce(0) { $0 + $1.totalIncome } / Double(incomeMonths.count)
        let avgExpense = expenseMonths.isEmpty ? 0 : expenseMonths.reduce(0) { $0 + $1.totalExpense } / Double(expenseMonths.count)
        let avgSavings = savingsMonths.isEmpty ? 0 : savingsMonths.reduce(0) { $0 + $1.savings } / Double(savingsMonths.count)
        
        let avgSavingsRate = avgIncome > 0 ? (avgSavings / avgIncome) * 100 : 0
        
        return CardView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Monthly Averages", subtitle: "Active Months")
                
                // 1. Avg Income
                ModernSummaryItem(
                    title: "Income",
                    value: CommonHelpers.formatCurrency(avgIncome),
                    color: .primaryText,
                    icon: "plus.circle",
                    isPositive: true
                )
                
                // 2. Avg Expense
                ModernSummaryItem(
                    title: "Expenses",
                    value: CommonHelpers.formatCurrency(avgExpense),
                    color: .primaryText,
                    icon: "minus.circle",
                    isPositive: false
                )
                
                // 3. Avg Net Savings
                ModernSummaryItem(
                    title: "Net Savings",
                    value: CommonHelpers.formatCurrencyWithSign(avgSavings),
                    color: avgSavings >= 0 ? .adaptiveGreen : .adaptiveRed,
                    icon: "suitcase",
                    isPositive: avgSavings >= 0
                )
                
                // 4. Avg Savings Rate
                ModernSummaryItem(
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", avgSavingsRate),
                    color: CommonHelpers.getSavingsRateColor(avgSavingsRate),
                    icon: "percent",
                    isPositive: avgSavingsRate >= 0
                )
            }
        }
    }
}

// MARK: - Custom Line Chart
struct TrendLineChart: View {
    let data: [MonthlyTrendData]
    let mode: MonthlyTrendsView.ChartMode
    
    @State private var selectedIndex: Int? = nil
    @State private var touchLocation: CGPoint = .zero
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            // Layout constants
            let xAxisHeight: CGFloat = 20
            let chartWidth = width
            let chartHeight = height - xAxisHeight
            
            let values = data.map { item in
                switch mode {
                case .income: return item.totalIncome
                case .expense: return item.totalExpense
                case .savings: return item.savings
                }
            }
            let maxAmount = (values.max() ?? 0) * 1.1
            let safeMaxAmount = maxAmount > 0 ? maxAmount : 1
            
            let color: Color = {
                switch mode {
                case .income: return .adaptiveGreen
                case .expense: return .adaptiveRed
                case .savings: return .blue
                }
            }()
            
            ZStack {
                // 1. Grid Lines (Horizontal & Vertical)
                ZStack {
                    // Horizontal Grid Lines
                    VStack {
                        ForEach(0..<3) { i in
                            Rectangle()
                                .fill(Color.secondarySystemFill)
                                .frame(height: 1)
                            if i < 2 { Spacer() }
                        }
                    }
                    
                    // Vertical Grid Lines (for each month)
                    HStack(spacing: 0) {
                        ForEach(0..<data.count, id: \.self) { i in
                            if i > 0 { Spacer() }
                            Rectangle()
                                .fill(Color.secondarySystemFill.opacity(0.5))
                                .frame(width: 1)
                        }
                    }
                }
                .frame(width: chartWidth, height: chartHeight)
                .position(x: chartWidth/2, y: chartHeight/2)
                    
                    // 2. Smooth Line Path
                    if data.count > 1 {
                        pathForValues(values, in: CGSize(width: chartWidth, height: chartHeight), maxValue: safeMaxAmount)
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    
                    // 3. Interaction Overlay (Points & Tooltip)
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                        let value = values[index]
                        let xPosition = chartWidth * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let yPosition = chartHeight - (chartHeight * CGFloat(value) / CGFloat(safeMaxAmount))
                        
                        // Invisible hit targets for better touch area
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: chartWidth / CGFloat(data.count), height: chartHeight)
                            .position(x: xPosition, y: chartHeight/2)
                        
                        // Normal Dots (Visible)
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(x: xPosition, y: yPosition)
                            .opacity(selectedIndex == nil ? 1 : (selectedIndex == index ? 1 : 0.0))
                    }
                    
                    // Active Selection Overlay
                    if let idx = selectedIndex, idx < data.count {
                        let item = data[idx]
                        let value = values[idx]
                        let xPosition = chartWidth * CGFloat(idx) / CGFloat(max(data.count - 1, 1))
                        let yPosition = chartHeight - (chartHeight * CGFloat(value) / CGFloat(safeMaxAmount))
                        
                        // Vertical Indicator Line
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 1, height: chartHeight)
                            .position(x: xPosition, y: chartHeight / 2)
                        
                        // Large Selected Dot
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .shadow(radius: 2)
                            .overlay(Circle().stroke(color, lineWidth: 2))
                            .position(x: xPosition, y: yPosition)
                        
                        // Tooltip
                        VStack(spacing: 4) {
                            Text(item.monthYearString)
                                .font(.appFont(10, weight: .bold))
                                .foregroundColor(.white)
                            Text("₹\(CommonHelpers.formatAmount(value))")
                                .font(.appFont(12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(6)
                        // Smart offset
                        .position(x: max(50, min(xPosition, chartWidth - 50)), y: max(yPosition - 40, 25))
                    }
                    
                    // 4. X-Axis Labels (Overlaid at bottom)
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                        let xPosition = chartWidth * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let interval = data.count > 12 ? (data.count > 20 ? 6 : 4) : (data.count > 6 ? 2 : 1)
                        
                        if index == 0 || index % interval == 0 {
                            Text(item.monthYearString)
                                .font(.appFont(10))
                                .foregroundColor(.secondaryText)
                                .position(x: xPosition, y: height - 10)
                        }
                    }
                }
                .frame(width: chartWidth, height: height)
                // Gesture
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let location = value.location
                            // Adjust for Y-Axis offset
                            let chartX = location.x
                            let step = chartWidth / CGFloat(max(data.count - 1, 1))
                            let rawIndex = Int(round(chartX / step))
                            let newIndex = max(0, min(rawIndex, data.count - 1))
                            
                            if selectedIndex != newIndex {
                                selectedIndex = newIndex
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }
                        }
                        .onEnded { _ in
                            selectedIndex = nil
                        }
                )
            }
        }
    }
    
    // Helper for Trend Line (Straight Lines)
    private func pathForValues(_ values: [Double], in size: CGSize, maxValue: Double) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        
        let stepX = size.width / CGFloat(values.count - 1)
        let points = values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: size.height - (size.height * CGFloat(value) / CGFloat(maxValue))
            )
        }
        
        path.move(to: points[0])
        
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        return path
    }


// MARK: - Preview
struct MonthlyTrendsView_Previews: PreviewProvider {
    
    // Mock Service for Monthly Trends
    private final class MockMonthlyTrendsRepoService: DataFetchRepoService {
        
        let shouldReturnEmptyData: Bool
        
        init(shouldReturnEmptyData: Bool = false) {
            self.shouldReturnEmptyData = shouldReturnEmptyData
        }
                
        func fetchAll<T>(from table: String, filters: [RepoQueryFilter], orderBy: String?) async throws -> [T] where T : Decodable {
            
            if shouldReturnEmptyData {
                return []
            }
            
            // Simulate latency
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Return Expense Summaries
            if T.self == FinancialMonthlySummary.self, table == "monthly_expense_summaries" {
                var summaries: [FinancialMonthlySummary] = []
                
                // Generate last 24 months of data
                for i in 0..<24 {
                    let date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
                    let year = Calendar.current.component(.year, from: date)
                    let month = Calendar.current.component(.month, from: date)
                    
                    summaries.append(FinancialMonthlySummary(
                        id: UUID(),
                        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                        year: year,
                        month: month,
                        totalAmount: Double.random(in: 20000...50000)
                    ))
                }
                
                if let typed = summaries as? [T] { return typed }
            }
            
            // Return Income Summaries
            if T.self == FinancialMonthlySummary.self, table == "monthly_income_summaries" {
                var summaries: [FinancialMonthlySummary] = []
                
                for i in 0..<24 {
                    let date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
                    let year = Calendar.current.component(.year, from: date)
                    let month = Calendar.current.component(.month, from: date)
                    
                    summaries.append(FinancialMonthlySummary(
                        id: UUID(),
                        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                        year: year,
                        month: month,
                        totalAmount: Double.random(in: 40000...60000)
                    ))
                }
                
                if let typed = summaries as? [T] { return typed }
            }
            
            return []
        }
    }
    
    static var previews: some View {
        MonthlyTrendsView(userId: "preview-user", repoService: MockMonthlyTrendsRepoService())
            .preferredColorScheme(.light)
            .previewDisplayName("Monthly Trends - Light")
        
        MonthlyTrendsView(userId: "preview-user", repoService: MockMonthlyTrendsRepoService(shouldReturnEmptyData: true))
            .preferredColorScheme(.dark)
            .previewDisplayName("Monthly Trends - Dark")
    }
}
