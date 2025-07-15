import SwiftUI

struct ExpenseDetailsView: View {
    @StateObject private var viewModel: ExpenseDetailsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var showingUpdateAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingDatePicker = false
    
    let expense: Expense
    
    init(expense: Expense) {
        self.expense = expense
        self._viewModel = StateObject(wrappedValue: ExpenseDetailsViewModel(expense: expense))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ExpenseNameField(viewModel: viewModel)
                    ExpenseAmountField(viewModel: viewModel)
                    ExpenseCategoryField(viewModel: viewModel)
                    ExpenseDateField(viewModel: viewModel, showingDatePicker: $showingDatePicker)
                    UpdateExpenseButton(viewModel: viewModel, showingUpdateAlert: $showingUpdateAlert)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.sora(16))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5)),
                
                trailing: Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            )
        }
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

// MARK: - Expense Name Field
struct ExpenseNameField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        InputSectionView(
            title: "Expense Name",
            icon: "bag.fill"
        ) {
            TextField("What did you spend on?", text: $viewModel.expenseName)
                .font(.sora(16, weight: .medium))
                .foregroundColor(.black)
                .onChange(of: viewModel.expenseName) { _ in
                    viewModel.validateForm()
                }
        }
    }
}

// MARK: - Expense Amount Field
struct ExpenseAmountField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        InputSectionView(
            title: "Amount",
            icon: "indianrupeesign.circle.fill"
        ) {
            HStack {
                Text("₹")
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("0.00", text: $viewModel.amountText)
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.black)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewModel.amountText) { _ in
                        viewModel.validateForm()
                    }
            }
        }
    }
}

// MARK: - Expense Category Field
struct ExpenseCategoryField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    
    var body: some View {
        InputSectionView(
            title: "Category",
            icon: "list.bullet.circle.fill"
        ) {
            CategorySelector(viewModel: viewModel)
        }
    }
}

// MARK: - Category Selector
struct CategorySelector: View {
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
                        Text(category.displayName)
                        Spacer()
                        if viewModel.selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                        }
                    }
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(viewModel.selectedCategory.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: viewModel.selectedCategory.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.selectedCategory.color)
                    )
                
                Text(viewModel.selectedCategory.displayName)
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Expense Date Field
struct ExpenseDateField: View {
    @ObservedObject var viewModel: ExpenseDetailsViewModel
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        InputSectionView(
            title: "Date",
            icon: "calendar.circle.fill"
        ) {
            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    Text(viewModel.formattedDate)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
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
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Update Expense")
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .frame(height: 55)
        }
        .background(viewModel.isFormValid ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.6))
        .cornerRadius(12)
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.horizontal, 20)
    }
}

// MARK: - Input Section View Helper
struct InputSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                    )
                
                Text(title)
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.white)
                )
                .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
