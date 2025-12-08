//
//  FinancialGoalListView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import SwiftUI

struct FinancialGoalListView: View {
    @StateObject private var viewModel: FinancialGoalViewModel
    @EnvironmentObject private var coordinator: MainCoordinator
    
    init(repoService: FinancialGoalRepoService) {
        self._viewModel = StateObject(wrappedValue: FinancialGoalViewModel(repoService: repoService))
    }
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchGoals()
                        }
                    }
                    .padding()
                }
            } else if viewModel.goals.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Financial Goals")
                        .font(.appFont(20, weight: .semibold))
                    Text("Set up goals to track your savings and larger expenses.")
                        .font(.appFont(16))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.goals) { goal in
                            GoalCardView(goal: goal)
                                .onTapGesture {
                                    coordinator.navigate(to: .financialGoalDetails(goal: goal))
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Financial Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    coordinator.navigate(to: .addFinancialGoal)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchGoals()
            }
        }
    }
}

struct GoalCardView: View {
    let goal: FinancialGoal
    
    private var currentAmount: Decimal {
        guard let contributions = goal.contributions else { return 0 }
        return contributions.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return Double(truncating: currentAmount as NSNumber) / Double(truncating: goal.targetAmount as NSNumber)
    }
    
    var body: some View {
        CardView(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.title)
                        .font(.appFont(18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    StatusPill(status: goal.status)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: goal.colorHex) ?? .blue)
                            .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)))
                    }
                }
                .frame(height: 8)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        Text(CommonHelpers.formatCurrency(NSDecimalNumber(decimal: currentAmount).doubleValue))
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Target")
                            .font(.appFont(12))
                            .foregroundColor(.secondaryText)
                        Text(CommonHelpers.formatCurrency(goal.targetAmount))
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.primaryText)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                    Text("Target Date: \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.appFont(12))
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
}

struct StatusPill: View {
    let status: FinancialGoalStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.appFont(12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
}

class MockFinancialGoalListRepoService: FinancialGoalRepoService {
    func fetchGoals() async throws -> [FinancialGoal] {
        return [
            FinancialGoal(
                id: UUID(),
                userId: UUID(),
                title: "Dream Car",
                colorHex: "#216DF3",
                targetAmount: 50000,
                targetDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
                status: .active,
                contributions: [
                    GoalContribution(id: 0, goalId: UUID(), amount: 15000, transactionDate: Date(), note: "Initial Savings")
                ]
            ),
             FinancialGoal(
                id: UUID(),
                userId: UUID(),
                title: "Europe Trip",
                colorHex: "#428F7D",
                targetAmount: 5000,
                targetDate: Date().addingTimeInterval(86400 * 180), // 6 months from now
                status: .completed,
                contributions: [
                    GoalContribution(id: 1, goalId: UUID(), amount: 5000, transactionDate: Date(), note: "Full amount")
                ]
            )
        ]
    }
    
    func addGoal(_ goal: FinancialGoal) async throws {}
    func updateGoal(_ goal: FinancialGoal) async throws {}
    func deleteGoal(id: UUID) async throws {}
    func addContribution(_ contribution: GoalContribution) async throws {}
    func deleteContribution(id: Int) async throws {}
    func updateContribution(_ contribution: GoalContribution) async throws {}
}

struct FinancialGoalListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
             FinancialGoalListView(repoService: MockFinancialGoalListRepoService())
        }
    }
}
