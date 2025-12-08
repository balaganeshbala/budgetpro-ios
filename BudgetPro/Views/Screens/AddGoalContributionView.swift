//
//  AddGoalContributionView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/12/25.
//

import SwiftUI

struct AddGoalContributionView: View {
    @StateObject private var viewModel: AddGoalContributionViewModel
    @EnvironmentObject private var coordinator: MainCoordinator
    @State private var showingDatePicker = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    let goalTitle: String
    
    init(repoService: FinancialGoalRepoService, goalId: UUID, goalTitle: String, contributionToEdit: GoalContribution? = nil) {
        _viewModel = StateObject(wrappedValue: AddGoalContributionViewModel(repoService: repoService, goalId: goalId, contributionToEdit: contributionToEdit))
        self.goalTitle = goalTitle
    }
    
    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    formContentCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .disableScrollViewBounce()
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Error overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Contribution" : "Add Contribution")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
             ToolbarItem(placement: .navigationBarLeading) {
                 Button(action: {
                     coordinator.pop()
                 }) {
                     Image(systemName: "chevron.left")
                         .foregroundColor(.primary)
                 }
             }
             
             ToolbarItem(placement: .navigationBarTrailing) {
                 if viewModel.isEditing {
                     Button(action: {
                         showingDeleteAlert = true
                     }) {
                         Image(systemName: "trash")
                             .foregroundColor(.red)
                     }
                 }
             }
         }
         .alert("Delete Contribution", isPresented: $showingDeleteAlert) {
             Button("Delete", role: .destructive) {
                 Task {
                     do {
                         try await viewModel.deleteContribution()
                         coordinator.pop()
                     } catch {
                         // Error handled in ViewModel
                     }
                 }
             }
             Button("Cancel", role: .cancel) { }
         } message: {
             Text("Are you sure you want to delete this contribution?")
         }
         .navigationBarBackButtonHidden(true)
        .overlay {
            if showingDatePicker {
                 DatePickerDialog(selectedDate: $viewModel.transactionDate, isPresented: $showingDatePicker)
            }
        }
    }
    
    private var formContentCard: some View {
        VStack(spacing: 24) {
            // Title Section
            HStack {
                Text("For \(goalTitle)")
                    .font(.appFont(16, weight: .medium))
                    .foregroundColor(.secondaryText)
                Spacer()
            }
            
            // Form Fields
            VStack(spacing: 24) {
                AppTextField(
                    hint: "Amount",
                    iconName: "indianrupeesign",
                    text: $viewModel.amountString,
                    keyboardType: .decimalPad,
                    submitLabel: .next
                )
                
                // Date Selector
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showingDatePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        
                        Text("Date")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(viewModel.transactionDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.appFont(14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .background(Color.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.inputBorder, lineWidth: 1)
                    )
                }
                
                AppTextField(
                    hint: "Note (Optional)",
                    iconName: "note.text",
                    text: $viewModel.note,
                    submitLabel: .done
                )
            }
            
            // Save Button
            Button(action: {
                Task {
                    do {
                        try await viewModel.saveContribution()
                        coordinator.pop()
                    } catch {
                        // Error handled in ViewModel
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ButtonProgressView()
                    } else {
                         Text(viewModel.isEditing ? "Update Contribution" : "Add Contribution")
                            .font(.appFont(16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            .modify {
                 if #available(iOS 26.0, *) {
                     $0.liquidGlassProminent()
                 } else {
                     $0.buttonStyle(.borderedProminent)
                 }
             }
            .tint(
                viewModel.isValid && !viewModel.isLoading
                    ? Color.primary
                    : Color.gray.opacity(0.6)
            )
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .padding(.top, 10)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}
