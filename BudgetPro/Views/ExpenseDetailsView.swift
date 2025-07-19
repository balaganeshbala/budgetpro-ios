import SwiftUI

struct ExpenseDetailsView: View {
    @StateObject private var viewModel: ExpenseDetailsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var showingUpdateAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingDatePicker = false
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
                    
                    Text("Update Expense")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
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
                        UpdateExpenseNameInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Amount Field
                        UpdateExpenseAmountInputField(viewModel: viewModel, focusedField: $focusedField)
                        
                        // Category Selector
                        UpdateExpenseCategorySelectorField(viewModel: viewModel)
                        
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
                }
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .ignoresSafeArea(.container, edges: .bottom)
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                UpdateLoadingOverlay()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $viewModel.selectedDate)
        }
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
        }
    }
}

// MARK: - Update Input Fields

struct UpdateExpenseNameInputField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    var focusedField: FocusState<ExpenseDetailsView.Field?>.Binding
    
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

struct UpdateExpenseAmountInputField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    var focusedField: FocusState<ExpenseDetailsView.Field?>.Binding
    
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

struct UpdateExpenseCategorySelectorField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            UpdateCategorySelectorMenu(viewModel: viewModel)
        }
    }
}

struct UpdateCategorySelectorMenu: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        Menu {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
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

struct UpdateExpenseDateSelectorField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
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
                    
                    Text(viewModel.formattedDate)
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && viewModel.hasChanges && !viewModel.isLoading
                    ? Color.gray.opacity(0.4)
                    : Color.gray.opacity(0.3)
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

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.sora(16, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
            )
        }
    }
}

// MARK: - Custom Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
