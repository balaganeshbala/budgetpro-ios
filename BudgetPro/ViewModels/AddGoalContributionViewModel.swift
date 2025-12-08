//
//  AddGoalContributionViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/12/25.
//

import Foundation

@MainActor
class AddGoalContributionViewModel: ObservableObject {
    @Published var amountString: String = ""
    @Published var transactionDate: Date = Date()
    @Published var note: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repoService: FinancialGoalRepoService
    private let goalId: UUID
    private let contributionToEdit: GoalContribution?
    
    var isEditing: Bool {
        contributionToEdit != nil
    }
    
    init(repoService: FinancialGoalRepoService, goalId: UUID, contributionToEdit: GoalContribution? = nil) {
        self.repoService = repoService
        self.goalId = goalId
        self.contributionToEdit = contributionToEdit
        
        if let contribution = contributionToEdit {
            self.amountString = String(NSDecimalNumber(decimal: contribution.amount).doubleValue)
            self.transactionDate = contribution.transactionDate
            self.note = contribution.note ?? ""
        }
    }
    
    var isValid: Bool {
        !amountString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Double(amountString) ?? 0) > 0
    }
    
    func saveContribution() async throws {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        let amount = Double(amountString) ?? 0
        
        do {
            if let existing = contributionToEdit {
                // Update existing contribution - create new instance
                let updated = GoalContribution(
                    id: existing.id,
                    goalId: existing.goalId,
                    amount: Decimal(amount),
                    transactionDate: transactionDate,
                    note: note.isEmpty ? nil : note
                )
                
                try await repoService.updateContribution(updated)
            } else {
                // Create new contribution - DB will auto-generate ID
                let newContribution = GoalContribution(
                    id: nil, // DB will auto-generate
                    goalId: goalId,
                    amount: Decimal(amount),
                    transactionDate: transactionDate,
                    note: note.isEmpty ? nil : note
                )
                
                try await repoService.addContribution(newContribution)
            }
            
            NotificationCenter.default.post(name: .financialDataChanged, object: nil)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to save contribution: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deleteContribution() async throws {
        guard let contributionId = contributionToEdit?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await repoService.deleteContribution(id: contributionId)
            NotificationCenter.default.post(name: .financialDataChanged, object: nil)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to delete contribution: \(error.localizedDescription)"
            throw error
        }
    }
}
