//
//  FinancialGoalDetailsView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/12/25.
//

import SwiftUI

struct FinancialGoalDetailsView: View {
    @StateObject private var viewModel: FinancialGoalDetailsViewModel
    @EnvironmentObject private var coordinator: MainCoordinator
    
    init(goal: FinancialGoal, repoService: FinancialGoalRepoService) {
        _viewModel = StateObject(wrappedValue: FinancialGoalDetailsViewModel(goal: goal, repoService: repoService))
    }
    
    // Calculated properties
    private var currentAmount: Decimal {
        guard let contributions = viewModel.goal.contributions else { return 0 }
        return contributions.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        guard viewModel.goal.targetAmount > 0 else { return 0 }
        return Double(truncating: currentAmount as NSNumber) / Double(truncating: viewModel.goal.targetAmount as NSNumber)
    }
    
    private var remainingAmount: Decimal {
        let target = Decimal(viewModel.goal.targetAmount)
        return max(0, target - currentAmount)
    }
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard
                    
                    // Contributions Section (Placeholder for now)
                    contributionsSection
                }
                .padding()
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    coordinator.navigate(to: .editFinancialGoal(goal: viewModel.goal))
                }
            }
        }
    }
    
    private var headerCard: some View {
        CardView(padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            VStack(spacing: 20) {
                // Title and Icon
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: viewModel.goal.colorHex) ?? .blue)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(viewModel.goal.icon)
                                .font(.system(size: 30))
                        )
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.goal.title)
                            .font(.appFont(20, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        StatusPill(status: viewModel.goal.status)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Progress Circle or Bar
                // Let's use a large circular progress for details
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                        .stroke(
                            Color(hex: viewModel.goal.colorHex) ?? .blue,
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: progress)
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.appFont(32, weight: .bold))
                            .foregroundColor(.primaryText)
                        Text("Completed")
                            .font(.appFont(14))
                            .foregroundColor(.secondaryText)
                    }
                }
                .frame(width: 150, height: 150)
                .padding(.vertical, 10)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    StatItem(title: "Target", value: CommonHelpers.formatCurrency(viewModel.goal.targetAmount), icon: "flag.checkered")
                    StatItem(title: "Current", value: CommonHelpers.formatCurrency(NSDecimalNumber(decimal: currentAmount).doubleValue), icon: "banknote")
                    StatItem(title: "Remaining", value: CommonHelpers.formatCurrency(NSDecimalNumber(decimal: remainingAmount).doubleValue), icon: "hourglass")
                    StatItem(title: "Date", value: viewModel.goal.targetDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
            }
        }
    }
    
    private var contributionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Contributions")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Add Contribution Button
                Button(action: {
                    coordinator.navigate(to: .addContribution(goalId: viewModel.goal.id, goalTitle: viewModel.goal.title))
                }) {
                    Label {
                        Text("Add")
                            .font(.appFont(14, weight: .semibold))
                    } icon: {
                        if #available(iOS 16.0, *) {
                            Image(systemName: "plus")
                                .fontWeight(.bold)
                        } else {
                            Image(systemName: "plus")
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            
            if let contributions = viewModel.goal.contributions, !contributions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(contributions.sorted(by: { $0.id! > $1.id! })) { contribution in
                        ContributionRow(contribution: contribution)
                            .onTapGesture {
                                coordinator.navigate(to: .editContribution(goalId: viewModel.goal.id, goalTitle: viewModel.goal.title, contribution: contribution))
                            }
                    }
                }
            } else {
                Text("No contributions yet.")
                    .font(.appFont(16))
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(.bottom, 16)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                Text(title)
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
            }
            
            Text(value)
                .font(.appFont(16, weight: .semibold))
                .foregroundColor(.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.groupedBackground)
        .cornerRadius(12)
    }
}

struct ContributionRow: View {
    let contribution: GoalContribution
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contribution.name)
                    .font(.appFont(16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text(contribution.transactionDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text("+\(CommonHelpers.formatCurrency(NSDecimalNumber(decimal: contribution.amount).doubleValue))")
                .font(.appFont(16, weight: .semibold))
                .foregroundColor(.green)
            
            Image(systemName: "chevron.right")
                .font(.appFont(14, weight: .regular))
                .foregroundStyle(Color.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FinancialGoalDetailsView_Previews: PreviewProvider {
    class MockRepoService: FinancialGoalRepoService {
        func fetchGoals() async throws -> [FinancialGoal] { [] }
        func addGoal(_ goal: FinancialGoal) async throws {}
        func updateGoal(_ goal: FinancialGoal) async throws {}
        func deleteGoal(id: UUID) async throws {}
        func addContribution(_ contribution: GoalContribution) async throws {}
        func deleteContribution(id: Int) async throws {}
        func updateContribution(_ contribution: GoalContribution) async throws {}
    }
    
    static var previews: some View {
        NavigationStack {
            FinancialGoalDetailsView(
                goal: FinancialGoal(
                    id: UUID(),
                    userId: UUID(),
                    title: "Dream Car",
                    icon: "🚗",
                    colorHex: "#216DF3",
                    targetAmount: 50000,
                    targetDate: Date().addingTimeInterval(86400 * 365),
                    status: .active,
                    contributions: [
                        GoalContribution(id: 0, goalId: UUID(), name: "Initial Savings", amount: 15000, transactionDate: Date()),
                        GoalContribution(id: 1, goalId: UUID(), name: "Bonus", amount: 5000, transactionDate: Date().addingTimeInterval(-86400 * 10))
                    ]
                ),
                repoService: MockRepoService()
            )
        }
    }
}
