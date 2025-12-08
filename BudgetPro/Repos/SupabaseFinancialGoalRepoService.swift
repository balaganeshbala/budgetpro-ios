//
//  SupabaseFinancialGoalRepoService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import Foundation

final class SupabaseFinancialGoalRepoService: FinancialGoalRepoService {
    
    private let supabase: SupabaseManager
    
    @MainActor
    init() {
        self.supabase = SupabaseManager.shared
    }
    
    func fetchGoals() async throws -> [FinancialGoal] {
        let userId = try await currentUserId()
        
        let goals: [FinancialGoal] = try await supabase.client
            .from("financial_goals")
            .select("*, contributions:goal_contributions(*)")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return goals
    }
    
    func addGoal(_ goal: FinancialGoal) async throws {
        try await supabase.client
            .from("financial_goals")
            .insert(goal)
            .execute()
    }
    
    func updateGoal(_ goal: FinancialGoal) async throws {
        try await supabase.client
            .from("financial_goals")
            .update(goal)
            .eq("goal_id", value: goal.id)
            .execute()
    }
    
    func deleteGoal(id: UUID) async throws {
        try await supabase.client
            .from("financial_goals")
            .delete()
            .eq("goal_id", value: id)
            .execute()
    }
    
    func addContribution(_ contribution: GoalContribution) async throws {
        try await supabase.client
            .from("goal_contributions")
            .insert(contribution)
            .execute()
    }
    
    func updateContribution(_ contribution: GoalContribution) async throws {
        try await supabase.client
            .from("goal_contributions")
            .update(contribution)
            .eq("id", value: contribution.id)
            .execute()
    }
    
    func deleteContribution(id: Int) async throws {
        try await supabase.client
            .from("goal_contributions")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    @MainActor
    private func currentUserId() async throws -> UUID {
        if let id = supabase.currentUser?.id {
            return id
        }
        let session = try await supabase.client.auth.session
        return session.user.id
    }
}
