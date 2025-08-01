import SwiftUI

struct ExpenseDetailsView: View {
    @StateObject private var viewModel: ExpenseDetailsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var showingUpdateAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingDatePicker = false
    @State private var showingCategoryPicker = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case expenseName
        case amount
    }
    
    let expense: Expense
    
    init(expense: Expense) {
        self.expense = expense
        self._viewModel = StateObject(wrappedValue: ExpenseDetailsViewModel(expense: expense))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Fixed Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Update Expense")
                        .font(.sora(20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
                .background(Color.primary)
                        
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
                            UpdateExpenseNameInputField(viewModel: viewModel, focusedField: $focusedField)
                            
                            // Amount Field
                            UpdateExpenseAmountInputField(viewModel: viewModel, focusedField: $focusedField)
                            
                            // Category Selector
                            UpdateExpenseCategorySelectorField(
                                viewModel: viewModel,
                                focusedField: $focusedField,
                                showingCategoryPicker: $showingCategoryPicker
                            )
                            
                            // Date Selector
                            UpdateExpenseDateSelectorField(
                                viewModel: viewModel,
                                showingDatePicker: $showingDatePicker
                            )
                            
                            // Update Expense Button
                            UpdateExpenseButton(viewModel: viewModel, showingUpdateAlert: $showingUpdateAlert)
                            
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
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                UpdateLoadingOverlay()
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
                    UpdateCategoryPickerDialog(
                        viewModel: viewModel,
                        isPresented: $showingCategoryPicker
                    )
                }
            }
        )
        .alert("Delete Expense", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteExpense()
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
        .alert("Update Expense", isPresented: $showingUpdateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Update") {
                Task {
                    await viewModel.updateExpense()
                }
            }
        } message: {
            Text("Are you sure you want to update this expense?")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isSuccess) { success in
            if success {
                showingSuccessAlert = true
            }
        }
        .onAppear {
            viewModel.loadExpenseData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .expenseName
            }
        }
    }
}


// MARK: - Update Input Fields

struct UpdateExpenseNameInputField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    var focusedField: FocusState<ExpenseDetailsView.Field?>.Binding
    
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

struct UpdateExpenseAmountInputField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    var focusedField: FocusState<ExpenseDetailsView.Field?>.Binding
    
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

struct UpdateExpenseCategorySelectorField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    var focusedField: FocusState<ExpenseDetailsView.Field?>.Binding
    @Binding var showingCategoryPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                // Dismiss keyboard immediately when tapping
                focusedField.wrappedValue = nil
                // Show category picker
                showingCategoryPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "triangle")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("Category")
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(viewModel.selectedCategory.displayName.uppercased())
                        .font(.sora(14, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                    
                    Image(systemName: "chevron.down")
                        .font(.sora(12))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct UpdateCategorySelectorMenu: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        Menu {
            ForEach(ExpenseCategory.userSelectableCategories, id: \.self) { category in
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
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(viewModel.selectedCategory.displayName.uppercased())
                    .font(.sora(14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                
                Image(systemName: "chevron.down")
                    .font(.sora(12))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct UpdateExpenseDateSelectorField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
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
                    
                    Text(viewModel.formattedDate)
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

// MARK: - Update Button
struct UpdateExpenseButton: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    @Binding var showingUpdateAlert: Bool
    
    var body: some View {
        Button(action: {
            if viewModel.hasChanges {
                showingUpdateAlert = true
            } else {
                viewModel.errorMessage = "No changes made"
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Update Expense")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && viewModel.hasChanges && !viewModel.isLoading
                    ? Color(red: 1.0, green: 0.4, blue: 0.4)
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || !viewModel.hasChanges || viewModel.isLoading)
        .padding(.top, 24)
    }
}

struct UpdateLoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.4, blue: 0.4)))
                        .scaleEffect(1.5)
                    
                    Text("Updating expense...")
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


// MARK: - Update Category Picker Dialog
struct UpdateCategoryPickerDialog: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Category picker content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Category")
                        .font(.sora(20, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Categories list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(ExpenseCategory.userSelectableCategories, id: \.self) { category in
                            HStack(spacing: 16) {
                                Image(systemName: category.iconName)
                                    .foregroundColor(category.color)
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text(category.displayName)
                                    .font(.sora(16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                if viewModel.selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.primary)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedCategory = category
                                viewModel.validateForm()
                                isPresented = false
                            }
                            
                            if category != ExpenseCategory.userSelectableCategories.last {
                                Divider()
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}

struct ExpenseDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseDetailsView(
            expense: Expense(
                id: 1,
                name: "Lunch",
                amount: 250.0,
                category: "Food",
                date: Date(),
                categoryIcon: "fork.knife",
                categoryColor: .orange
            )
        )
    }
}
