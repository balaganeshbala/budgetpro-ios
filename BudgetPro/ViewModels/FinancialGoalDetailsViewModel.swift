//
//  FinancialGoalDetailsViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/12/25.
//

import Foundation

@MainActor
class FinancialGoalDetailsViewModel: ObservableObject {
    @Published var goal: FinancialGoal
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repoService: FinancialGoalRepoService
    
    init(goal: FinancialGoal, repoService: FinancialGoalRepoService) {
        self.goal = goal
        self.repoService = repoService
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataChange), name: .financialDataChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleDataChange() {
        Task {
            await refreshGoal()
        }
    }
    
    func refreshGoal() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all goals and find the updated one
            let goals = try await repoService.fetchGoals()
            if let updatedGoal = goals.first(where: { $0.id == goal.id }) {
                self.goal = updatedGoal
            }
        } catch {
            errorMessage = "Failed to refresh goal: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
