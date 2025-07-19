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
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDatePicker = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case expenseName
        case amount
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.34, green: 0.71, blue: 0.64), Color(red: 0.30, green: 0.64, blue: 0.58)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Add Expense")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("") { }
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
                
                // Content Card
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        // Title
                        HStack {
                            Text("Expense Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.top, 24)
                        
                        // Expense Name Field
                        ExpenseNameInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Amount Field
                        ExpenseAmountInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Category Selector
                        ExpenseCategorySelectorField(viewModel: viewModel)
                        
                        // Date Selector
                        ExpenseDateSelectorField(
                            viewModel: viewModel,
                            showingDatePicker: $showingDatePicker
                        )
                        
                        // Add Expense Button
                        AddExpenseButton(viewModel: viewModel)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 24)
                }
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .ignoresSafeArea(.container, edges: .bottom)
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $viewModel.selectedDate)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
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
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}



// MARK: - Input Fields

struct ExpenseNameInputField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    var focusedField: FocusState<AddExpenseView.Field?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bag")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                Text("Expense Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.34, green: 0.71, blue: 0.64))
            }
            
            HStack(spacing: 12) {
                Image(systemName: "bag")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                
                TextField("What did you spend on?", text: $viewModel.expenseName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .textInputAutocapitalization(.words)
                    .focused(focusedField, equals: .expenseName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField.wrappedValue = .amount
                    }
                    .onChange(of: viewModel.expenseName) { _ in
                        if viewModel.expenseName.count > 25 {
                            viewModel.expenseName = String(viewModel.expenseName.prefix(25))
                        }
                        viewModel.validateForm()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField.wrappedValue == .expenseName ? Color(red: 0.34, green: 0.71, blue: 0.64) : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct ExpenseAmountInputField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    var focusedField: FocusState<AddExpenseView.Field?>.Binding
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "indianrupeesign")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                
                TextField("Amount", text: $viewModel.amountText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .amount)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField.wrappedValue = nil
                    }
                    .onChange(of: viewModel.amountText) { newValue in
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
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField.wrappedValue == .amount ? Color(red: 0.34, green: 0.71, blue: 0.64) : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct ExpenseCategorySelectorField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            CategorySelectorMenu(viewModel: viewModel)
        }
    }
}

struct CategorySelectorMenu: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    
    var body: some View {
        Menu {
            ForEach(viewModel.categories, id: \.self) { category in
                Button(action: {
                    viewModel.selectedCategory = category
                    viewModel.validateForm()
                }) {
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(category.color)
                        Text(category.displayName)
                        if viewModel.selectedCategory == category {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "triangle")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                
                Text("Category")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(viewModel.selectedCategory.displayName.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.34, green: 0.71, blue: 0.64))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.34, green: 0.71, blue: 0.64))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ExpenseDateSelectorField: View {
    @ObservedObject var viewModel: AddExpenseViewModel
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                showingDatePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("Date")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDateForDisplay)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.34, green: 0.71, blue: 0.64))
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                    ? Color.gray.opacity(0.4)
                    : Color.gray.opacity(0.3)
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
                        .font(.system(size: 16, weight: .medium))
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
