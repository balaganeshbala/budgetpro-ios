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
                gradient: Gradient(colors: [Color(red: 0.2, green: 0.6, blue: 0.5), Color(red: 0.18, green: 0.54, blue: 0.45)]),
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
        .overlay(
            Group {
                if showingDatePicker {
                    DatePickerDialog(
                        selectedDate: $viewModel.selectedDate,
                        isPresented: $showingDatePicker
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
        }
    }
}

// MARK: - Reusable Floating Label Input Field

struct FloatingLabelTextField: View {
    let label: String
    let iconName: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let submitLabel: SubmitLabel
    let textCapitalization: TextInputAutocapitalization
    let onSubmit: () -> Void
    let onChange: (String) -> Void
    let isFocused: Bool
    
    @FocusState private var isTextFieldFocused: Bool
    
    private var isLabelFloating: Bool {
        isFocused || !text.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                
                TextField("", text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textCapitalization)
                    .submitLabel(submitLabel)
                    .focused($isTextFieldFocused)
                    .onSubmit(onSubmit)
                    .onChange(of: text, perform: onChange)
                    .frame(height: 55)
            }
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .contentShape(Rectangle())
            
            // Floating Label
            Text(label)
                .font(.system(size: isLabelFloating ? 12 : 16, weight: .medium))
                .foregroundColor(isLabelFloating ? Color(red: 0.2, green: 0.6, blue: 0.5) : .gray)
                .padding(.horizontal, 4)
                .background(isLabelFloating ? Color.white : Color.clear)
                .offset(
                    x: isLabelFloating ? 15 : 45,
                    y: isLabelFloating ? -28 : 0
                )
                .animation(.easeInOut(duration: 0.2), value: isLabelFloating)
                .allowsHitTesting(false)
        }
        .onTapGesture {
            isTextFieldFocused = true
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
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
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
                        .font(.system(size: 16, weight: .semibold))
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

// MARK: - Date Picker Dialog
struct DatePickerDialog: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Select Date")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 180)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.2, green: 0.6, blue: 0.5))
                    .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
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
