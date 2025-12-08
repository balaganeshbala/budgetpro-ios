//
//  FinancialGoalViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import Foundation

@MainActor
class FinancialGoalViewModel: ObservableObject {
    @Published var goals: [FinancialGoal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repoService: FinancialGoalRepoService
    private var isLoaded = false
    
    // Inject the dependency; default to Supabase implementation
    init(repoService: FinancialGoalRepoService) {
        self.repoService = repoService
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataChange), name: .financialDataChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleDataChange() {
        Task {
            await fetchGoals(forceRefresh: true)
        }
    }
    
    func fetchGoals(forceRefresh: Bool = false) async {
        guard !isLoaded || forceRefresh else { return }
        
        isLoading = true
        errorMessage = nil
        do {
            goals = try await repoService.fetchGoals()
            isLoaded = true
        } catch {
            errorMessage = "Failed to fetch goals: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func deleteGoal(at offsets: IndexSet) async {
        for index in offsets {
            let goal = goals[index]
            do {
                try await repoService.deleteGoal(id: goal.id)
                // Remove locally if successful (or re-fetch)
                goals.remove(at: index)
            } catch {
                errorMessage = "Failed to delete goal: \(error.localizedDescription)"
            }
        }
    }
}
