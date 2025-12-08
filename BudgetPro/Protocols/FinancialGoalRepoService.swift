//
//  FinancialGoalRepoService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import Foundation

protocol FinancialGoalRepoService {
    func fetchGoals() async throws -> [FinancialGoal]
    func addGoal(_ goal: FinancialGoal) async throws
    func updateGoal(_ goal: FinancialGoal) async throws
    func deleteGoal(id: UUID) async throws
    func addContribution(_ contribution: GoalContribution) async throws
    func updateContribution(_ contribution: GoalContribution) async throws
    func deleteContribution(id: Int) async throws
}
