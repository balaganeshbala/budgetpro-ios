//
//  AddFinancialGoalView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 07/12/25.
//

import SwiftUI

struct AddFinancialGoalView: View {
    @StateObject private var viewModel: AddFinancialGoalViewModel
    @EnvironmentObject private var coordinator: MainCoordinator
    @State private var showingDatePicker = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingUpdateAlert = false
    
    init(repoService: FinancialGoalRepoService, goalToEdit: FinancialGoal? = nil) {
        _viewModel = StateObject(wrappedValue: AddFinancialGoalViewModel(repoService: repoService, goalToEdit: goalToEdit))
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
        .navigationTitle(viewModel.isEditing ? "Edit Goal" : "Add Goal")
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
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteGoal()
                        coordinator.popToRoot()
                    } catch {
                        // Error handled in ViewModel
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
        .alert("Update Goal", isPresented: $showingUpdateAlert) {
            Button("Update") {
                Task {
                    do {
                        try await viewModel.saveGoal()
                        coordinator.popToRoot()
                    } catch {
                        // Error handled in ViewModel
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to update this goal?")
        }
        .navigationBarBackButtonHidden(true)
        .overlay {
            if showingDatePicker {
                 DatePickerDialog(selectedDate: $viewModel.targetDate, isPresented: $showingDatePicker)
            }
        }
    }
    
    private var formContentCard: some View {
        VStack(spacing: 24) {
            // Title Section
            HStack {
            // Title Section
            HStack {
                Text(viewModel.isEditing ? "Update Goal" : "New Goal")
                    .font(.appFont(20, weight: .semibold))
                    .foregroundColor(.primaryText)
                Spacer()
            }
                Spacer()
            }
            
            // Form Fields
            VStack(spacing: 24) {
                AppTextField(
                    hint: "Goal Title",
                    iconName: "target",
                    text: $viewModel.title,
                    submitLabel: .next,
                    textCapitalization: .words
                )
                
                AppTextField(
                    hint: "Target Amount",
                    iconName: "indianrupeesign",
                    text: $viewModel.targetAmountString,
                    keyboardType: .decimalPad,
                    submitLabel: .done
                )
                
                // Date Selector (styled like TransactionDateSelectorField)
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showingDatePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        
                        Text("Target Date")
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(viewModel.targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.appFont(14, weight: .semibold)) // Match TransactionFormView style roughly
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
                
                // Emoji Icon Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Icon")
                        .font(.appFont(14, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(viewModel.availableIcons, id: \.self) { icon in
                            Text(icon)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedIcon == icon ? Color.primary.opacity(0.1) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedIcon == icon ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    viewModel.selectedIcon = icon
                                }
                        }
                    }
                }
                
                // Color Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Color")
                        .font(.appFont(14, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(viewModel.availableColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .gray)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primaryText, lineWidth: viewModel.selectedColorHex == colorHex ? 2 : 0)
                                        .padding(-4)
                                )
                                .onTapGesture {
                                    viewModel.selectedColorHex = colorHex
                                }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Save Button
            Button(action: {
                if viewModel.isEditing {
                    showingUpdateAlert = true
                } else {
                    Task {
                        do {
                            try await viewModel.saveGoal()
                            coordinator.pop()
                        } catch {
                            // Error is handled in ViewModel
                        }
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ButtonProgressView()
                    } else {
                        Text(viewModel.isEditing ? "Update Goal" : "Save Goal")
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
                !viewModel.isValid || viewModel.isLoading || (viewModel.isEditing && !viewModel.hasChanges)
                    ? Color.gray.opacity(0.6)
                    : Color.primary
            )
            .disabled(!viewModel.isValid || viewModel.isLoading || (viewModel.isEditing && !viewModel.hasChanges))
            .padding(.top, 10)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview
struct AddFinancialGoalView_Previews: PreviewProvider {
    class MockFinancialGoalRepoService: FinancialGoalRepoService {
        func fetchGoals() async throws -> [FinancialGoal] { [] }
        func addGoal(_ goal: FinancialGoal) async throws {}
        func updateGoal(_ goal: FinancialGoal) async throws {}
        func deleteGoal(id: UUID) async throws {}
        func addContribution(_ contribution: GoalContribution) async throws {}
        func deleteContribution(id: Int) async throws {}
        func updateContribution(_ contribution: GoalContribution) async throws {}
    }
    
    static var previews: some View {
        AddFinancialGoalView(repoService: MockFinancialGoalRepoService())
    }
}
