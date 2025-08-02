//
//  AddExpenseView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 17/07/25.
//

import SwiftUI

// MARK: - Add Expense View
struct AddExpenseView: View {
    @StateObject private var viewModel = AddExpenseViewModel()
    @State private var showingDatePicker = false
    @State private var showingCategoryPicker = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss // Add this for proper dismissal
    
    enum Field {
        case expenseName
        case amount
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping on scroll area
                        focusedField = nil
                    }
                
                // Content Card
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        // Title
                        HStack {
                            Text("Expense Details")
                                .font(.sora(20, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.top, 24)
                        
                        // Expense Name Field
                        ExpenseNameInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Amount Field
                        ExpenseAmountInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Category Selector
                        DropdownSelectorField(
                            label: "Category",
                            iconName: "triangle",
                            selectedItem: viewModel.selectedCategory,
                            itemDisplayName: { $0.displayName },
                            onTap: { showingCategoryPicker = true },
                            focusedField: $focusedField
                        )
                        
                        // Date Selector
                        ExpenseDateSelectorField(
                            viewModel: viewModel,
                            showingDatePicker: $showingDatePicker
                        )
                        
                        // Add Expense Button - Modified to dismiss on success
                        ModifiedAddExpenseButton(viewModel: viewModel, dismiss: dismiss)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: UIScreen.main.bounds.height - 150)
                }
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .ignoresSafeArea(.container, edges: .bottom)
                .onTapGesture {
                    // Dismiss keyboard when tapping on the content area
                    focusedField = nil
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Configure navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.primary)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor.white
            
            viewModel.loadInitialData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .expenseName
            }
        }
        .overlay(
            Group {
                if showingDatePicker {
                    DatePickerDialog(
                        selectedDate: $viewModel.selectedDate,
                        isPresented: $showingDatePicker
                    )
                }
                
                if showingCategoryPicker {
                    DropdownPickerDialog(
                        title: "Select Category",
                        items: ExpenseCategory.userSelectableCategories,
                        selectedItem: viewModel.selectedCategory,
                        onItemSelected: { category in
                            viewModel.selectedCategory = category
                            viewModel.validateForm()
                        },
                        itemDisplayName: { $0.displayName },
                        itemIcon: { $0.iconName },
                        itemColor: { $0.color },
                        isPresented: $showingCategoryPicker
                    )
                }
            }
        )
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("Add Another") {
                showingSuccessAlert = false
                viewModel.resetForm()
            }
            Button("Done") {
                showingSuccessAlert = false
                dismiss() // Navigate back to home
            }
        } message: {
            Text("Expense added successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onReceive(viewModel.$isSuccess) { isSuccess in
            if isSuccess {
                showingSuccessAlert = true
            }
        }
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if !errorMessage.isEmpty {
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Modified Add Expense Button
struct ModifiedAddExpenseButton: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    let dismiss: DismissAction
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.addExpense()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Save Expense")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                    ? Color(red: 1.0, green: 0.4, blue: 0.4)
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.top, 24)
    }
}


// MARK: - Input Fields

struct ExpenseNameInputField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    var focusedField: FocusState<AddExpenseView.Field?>.Binding
    
    var body: some View {
        FloatingLabelTextField(
            label: "Expense Name",
            iconName: "bag",
            text: $viewModel.expenseName,
            keyboardType: .default,
            submitLabel: .next,
            textCapitalization: .words,
            onSubmit: {
                focusedField.wrappedValue = .amount
            },
            onChange: { _ in
                if viewModel.expenseName.count > 25 {
                    viewModel.expenseName = String(viewModel.expenseName.prefix(25))
                }
                viewModel.validateForm()
            },
            isFocused: focusedField.wrappedValue == .expenseName
        )
        .focused(focusedField, equals: .expenseName)
    }
}

struct ExpenseAmountInputField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    var focusedField: FocusState<AddExpenseView.Field?>.Binding
    
    var body: some View {
        FloatingLabelTextField(
            label: "Amount",
            iconName: "indianrupeesign",
            text: $viewModel.amountText,
            keyboardType: .decimalPad,
            submitLabel: .done,
            textCapitalization: .never,
            onSubmit: {
                focusedField.wrappedValue = nil
            },
            onChange: { newValue in
                let filtered = newValue.filter { "0123456789.".contains($0) }
                let components = filtered.components(separatedBy: ".")
                if components.count > 2 {
                    viewModel.amountText = components[0] + "." + components[1]
                } else if components.count == 2 && components[1].count > 2 {
                    viewModel.amountText = components[0] + "." + String(components[1].prefix(2))
                } else {
                    viewModel.amountText = filtered
                }
                viewModel.validateForm()
            },
            isFocused: focusedField.wrappedValue == .amount
        )
        .focused(focusedField, equals: .amount)
    }
}



struct ExpenseDateSelectorField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showingDatePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("Date")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDateForDisplay)
                        .font(.sora(14, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Add Expense Button
struct AddExpenseButton: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.addExpense()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Save Expense")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                    ? Color(red: 1.0, green: 0.4, blue: 0.4)
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.top, 24)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.4, blue: 0.4)))
                        .scaleEffect(1.5)
                    
                    Text("Adding expense...")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
                .padding(32)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            )
    }
}

struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
    }
}
