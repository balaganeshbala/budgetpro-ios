//
//  AddFinancialGoalViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import Foundation
import SwiftUI

@MainActor
class AddFinancialGoalViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var targetAmountString: String = ""
    @Published var targetDate: Date = Date().addingTimeInterval(86400 * 30) // Default 30 days
    @Published var selectedColorHex: String = "#216DF3" // Default Primary Blue
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Predefined colors for selection
    let availableColors: [String] = [
        "#216DF3", // Blue
        "#E640A6", // Pink
        "#428F7D", // Green
        "#FF6B6B", // Red
        "#FFA500", // Orange
        "#800080", // Purple
        "#FFD700", // Gold
        "#008080"  // Teal
    ]
    
    private let repoService: FinancialGoalRepoService
    private let goalToEdit: FinancialGoal?
    
    var isEditing: Bool {
        goalToEdit != nil
    }
    
    init(repoService: FinancialGoalRepoService, goalToEdit: FinancialGoal? = nil) {
        self.repoService = repoService
        self.goalToEdit = goalToEdit
        
        if let goal = goalToEdit {
            self.title = goal.title
            self.targetAmountString = String(goal.targetAmount)
            self.targetDate = goal.targetDate
            self.selectedColorHex = goal.colorHex
        }
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(targetAmountString) ?? 0 > 0
    }
    
    var hasChanges: Bool {
        guard let goal = goalToEdit else { return true }
        
        // Compare current values with initial goal values
        let amount = Double(targetAmountString) ?? 0
        let isTitleChanged = title != goal.title
        let isAmountChanged = abs(amount - goal.targetAmount) > 0.01
        let isDateChanged = !Calendar.current.isDate(targetDate, inSameDayAs: goal.targetDate) // Ignore time differences if any
        let isColorChanged = selectedColorHex != goal.colorHex
        
        return isTitleChanged || isAmountChanged || isDateChanged || isColorChanged
    }
    
    func saveGoal() async throws {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let amount = Double(targetAmountString) ?? 0
        
        do {
            if let existingGoal = goalToEdit {
                // Update existing goal
                var updatedGoal = existingGoal
                updatedGoal.title = title
                updatedGoal.targetAmount = amount
                updatedGoal.targetDate = targetDate
                updatedGoal.colorHex = selectedColorHex
                
                try await repoService.updateGoal(updatedGoal)
            } else {
                // Create new goal
                let userId: UUID
                if let id = SupabaseManager.shared.currentUser?.id {
                    userId = id
                } else {
                    let session = try await SupabaseManager.shared.client.auth.session
                    userId = session.user.id
                }
                
                let newGoal = FinancialGoal(
                    id: UUID(),
                    userId: userId,
                    title: title,
                    colorHex: selectedColorHex,
                    targetAmount: amount,
                    targetDate: targetDate,
                    status: .active,
                    contributions: nil
                )
                
                try await repoService.addGoal(newGoal)
            }
            
            NotificationCenter.default.post(name: .financialDataChanged, object: nil)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to save goal: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deleteGoal() async throws {
        guard let goalId = goalToEdit?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await repoService.deleteGoal(id: goalId)
            NotificationCenter.default.post(name: .financialDataChanged, object: nil)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
            throw error
        }
    }
}
