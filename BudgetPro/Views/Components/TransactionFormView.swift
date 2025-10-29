//
//  TransactionFormView.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import SwiftUI

// MARK: - Transaction Type Enum

extension TransactionType {
    var title: String {
        switch self {
        case .expense: return "Expense Details"
        case .income: return "Income Details"
        case .majorExpense: return "Major Expense Details"
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .expense: return "Add Expense"
        case .income: return "Add Income"
        case .majorExpense: return "Add Major Expense"
        }
    }
    
    var updateNavigationTitle: String {
        switch self {
        case .expense: return "Update Expense"
        case .income: return "Update Income"
        case .majorExpense: return "Update Major Expense"
        }
    }
    
    var nameFieldLabel: String {
        switch self {
        case .expense: return "Expense Name"
        case .income: return "Income Source"
        case .majorExpense: return "Major Expense Name"
        }
    }
    
    var nameFieldIcon: String {
        switch self {
        case .expense: return "bag"
        case .income: return "dollarsign.circle"
        case .majorExpense: return "creditcard.trianglebadge.exclamationmark"
        }
    }
    
    var saveButtonText: String {
        switch self {
        case .expense: return "Save Expense"
        case .income: return "Save Income"
        case .majorExpense: return "Save Major Expense"
        }
    }
    
    var updateButtonText: String {
        switch self {
        case .expense: return "Update Expense"
        case .income: return "Update Income"
        case .majorExpense: return "Update Major Expense"
        }
    }
    
    var loadingText: String {
        switch self {
        case .expense: return "Adding expense..."
        case .income: return "Adding income..."
        case .majorExpense: return "Adding major expense..."
        }
    }
    
    var updateLoadingText: String {
        switch self {
        case .expense: return "Updating expense..."
        case .income: return "Updating income..."
        case .majorExpense: return "Updating major expense..."
        }
    }
}

// MARK: - Transaction Form Mode
enum TransactionFormMode {
    case add
    case update
    
    var isUpdate: Bool {
        return self == .update
    }
}

// MARK: - Segregated Protocols (ISP/LSP)

// Core state shared by all transaction forms
@MainActor
protocol TransactionFormStateProtocol: ObservableObject {
    var transactionName: String { get set }
    var amountText: String { get set }
    var selectedDate: Date { get set }
    var notes: String { get set }
    var isLoading: Bool { get }
    var errorMessage: String { get }
    var isSuccess: Bool { get }
    var isFormValid: Bool { get }
    var formattedDateForDisplay: String { get }
    var hasChanges: Bool { get }
    var successMessage: String { get }
    
    func loadInitialData()
    func validateForm()
    func resetForm()
    func clearError()
}

// Capability protocols
@MainActor
protocol AddTransactionActions {
    func saveTransaction() async
}

@MainActor
protocol EditTransactionActions {
    func updateTransaction() async
    func deleteTransaction() async
}

// MARK: - Transaction Field Enum
enum TransactionField {
    case name
    case amount
    case notes
}

// MARK: - Generic Transaction Form View
struct TransactionFormView<ViewState: TransactionFormStateProtocol, CategoryType: CategoryProtocol>: View {
    @StateObject private var viewModel: ViewState
    @State private var showingDatePicker = false
    @State private var showingCategoryPicker = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingUpdateAlert = false
    @FocusState private var focusedField: TransactionField?
    @Environment(\.dismiss) private var dismiss
    
    let transactionType: TransactionType
    let mode: TransactionFormMode
    let categories: [CategoryType]
    let selectedCategory: CategoryType
    let onCategorySelected: (CategoryType) -> Void
    
    init(
        viewModel: @autoclosure @escaping () -> ViewState,
        transactionType: TransactionType,
        mode: TransactionFormMode,
        categories: [CategoryType],
        selectedCategory: CategoryType,
        onCategorySelected: @escaping (CategoryType) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.transactionType = transactionType
        self.mode = mode
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.onCategorySelected = onCategorySelected
    }
    
    // MARK: - Computed Properties
    private var navigationTitle: String {
        mode.isUpdate ? transactionType.updateNavigationTitle : transactionType.navigationTitle
    }
    
    private var mainContent: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea(.all)
            
            formScrollView
            
            if viewModel.isLoading {
                LoadingOverlay(titleText: mode.isUpdate ? transactionType.updateLoadingText : transactionType.loadingText)
            }
        }
    }
    
    private var formScrollView: some View {
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
            focusedField = nil
        }
    }
    
    private var formContentCard: some View {
        VStack(spacing: 24) {
            titleSection
            formFields
            actionButton
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var titleSection: some View {
        HStack {
            Text(transactionType.title)
                .font(.appFont(20, weight: .semibold))
                .foregroundColor(.primaryText)
            Spacer()
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 24) {
            TransactionNameInputField(
                viewModel: viewModel,
                focusedField: $focusedField,
                transactionType: transactionType
            )
            
            TransactionAmountInputField(
                viewModel: viewModel,
                focusedField: $focusedField
            )
            
            TransactionCategorySelectorField(
                selectedCategory: selectedCategory,
                onTap: { showingCategoryPicker = true }
            )
            
            TransactionDateSelectorField(
                viewModel: viewModel,
                showingDatePicker: $showingDatePicker
            )
            
            // Notes field for major expenses only
            if (transactionType == .majorExpense) {
                TransactionNotesInputField(
                    viewModel: viewModel,
                    focusedField: $focusedField
                )
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch mode {
        case .add:
            if let addCapable = viewModel as? any AddTransactionActions {
                TransactionSaveButton(
                    viewModel: AnyAddAction(addCapable, state: viewModel),
                    transactionType: transactionType
                )
            }
        case .update:
            if let updateCapable = viewModel as? any EditTransactionActions {
                TransactionUpdateButton(
                    viewModel: AnyUpdateAction(updateCapable, state: viewModel),
                    transactionType: transactionType,
                    showingUpdateAlert: $showingUpdateAlert
                )
            }
        }
    }
    
    var body: some View {
        mainContent
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .font(.title3)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if mode.isUpdate, let _ = viewModel as? any EditTransactionActions {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear(perform: handleViewAppear)
            .onDisappear(perform: handleViewDisappear)
            .overlay(overlayDialogs)
            .alert("Success", isPresented: $showingSuccessAlert, actions: successAlertActions, message: successAlertMessage)
            .alert("Error", isPresented: $showingErrorAlert, actions: errorAlertActions, message: errorAlertMessage)
            .alert(deleteAlertTitle, isPresented: $showingDeleteAlert, actions: deleteAlertActions, message: deleteAlertMessage)
            .alert(updateAlertTitle, isPresented: $showingUpdateAlert, actions: updateAlertActions, message: updateAlertMessage)
            .onChange(of: viewModel.isSuccess, perform: handleSuccessChange)
            .onChange(of: viewModel.errorMessage, perform: handleErrorChange)
    }
    
    // MARK: - Alert and Dialog Properties
    private var transactionName: String {
        String(transactionType.title.dropLast(8))
    }
    
    private var deleteAlertTitle: String {
        "Delete \(transactionName)"
    }
    
    private var updateAlertTitle: String {
        "Update \(transactionName)"
    }
    
    @ViewBuilder
    private var overlayDialogs: some View {
        Group {
            if showingDatePicker {
                DatePickerDialog(
                    selectedDate: $viewModel.selectedDate,
                    isPresented: $showingDatePicker
                )
            }
            
            if showingCategoryPicker {
                categoryPickerDialog
            }
        }
    }
    
    private var categoryPickerDialog: some View {
        DropdownPickerDialog(
            title: "Select Category",
            items: categories,
            selectedItem: selectedCategory,
            onItemSelected: handleCategorySelection,
            itemDisplayName: { $0.displayName },
            itemIcon: { $0.iconName },
            itemColor: { $0.color },
            isPresented: $showingCategoryPicker
        )
    }
    
    @ViewBuilder
    private func successAlertActions() -> some View {
        if mode.isUpdate {
            Button("OK") {
                // Navigate back to root view (Home screen)
                navigateToRoot()
            }
        } else {
            Button("Add Another") {
                showingSuccessAlert = false
                viewModel.resetForm()
            }
            Button("Done") {
                showingSuccessAlert = false
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private func successAlertMessage() -> some View {
        let message = mode.isUpdate ? viewModel.successMessage : "\(transactionName) added successfully!"
        Text(message)
    }
    
    @ViewBuilder
    private func errorAlertActions() -> some View {
        Button("OK") { }
    }
    
    @ViewBuilder
    private func errorAlertMessage() -> some View {
        Text(viewModel.errorMessage)
    }
    
    @ViewBuilder
    private func deleteAlertActions() -> some View {
        Button("Cancel", role: .cancel) { }
        if let deleteCapable = viewModel as? any EditTransactionActions {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteCapable.deleteTransaction()
                }
            }
        }
    }
    
    @ViewBuilder
    private func deleteAlertMessage() -> some View {
        Text("Are you sure you want to delete this \(transactionName.lowercased())? This action cannot be undone.")
    }
    
    @ViewBuilder
    private func updateAlertActions() -> some View {
        Button("Cancel", role: .cancel) { }
        if let updateCapable = viewModel as? any EditTransactionActions {
            Button("Update") {
                Task {
                    await updateCapable.updateTransaction()
                }
            }
        }
    }
    
    @ViewBuilder
    private func updateAlertMessage() -> some View {
        Text("Are you sure you want to update this \(transactionName.lowercased())?")
    }
    
    // MARK: - Action Handlers
    private func handleViewAppear() {
        viewModel.loadInitialData()
    }
    
    private func handleViewDisappear() {
        // Dismiss keyboard when view disappears
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func navigateToRoot() {
        // Find the navigation controller and pop to root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
                if let navController = viewController as? UINavigationController {
                    return navController
                }
                if let tabController = viewController as? UITabBarController,
                   let selectedViewController = tabController.selectedViewController {
                    return findNavigationController(from: selectedViewController)
                }
                for child in viewController.children {
                    if let navController = findNavigationController(from: child) {
                        return navController
                    }
                }
                return nil
            }
            
            if let navController = findNavigationController(from: rootViewController) {
                navController.popToRootViewController(animated: true)
            }
        }
    }
    
    private func handleCategorySelection(category: CategoryType) {
        onCategorySelected(category)
        viewModel.validateForm()
    }
    
    private func handleSuccessChange(_ isSuccess: Bool) {
        if isSuccess {
            showingSuccessAlert = true
        }
    }
    
    private func handleErrorChange(_ errorMessage: String) {
        if !errorMessage.isEmpty {
            showingErrorAlert = true
        }
    }
}

// MARK: - Type-erased wrappers for action buttons

// These are simple holders; they do not need ObservableObject.
final class AnyAddAction<State: TransactionFormStateProtocol> {
    let action: AddTransactionActions
    let state: State
    
    init(_ action: AddTransactionActions, state: State) {
        self.action = action
        self.state = state
    }
}

final class AnyUpdateAction<State: TransactionFormStateProtocol> {
    let action: EditTransactionActions
    let state: State
    
    init(_ action: EditTransactionActions, state: State) {
        self.action = action
        self.state = state
    }
}

// MARK: - Input Fields

struct TransactionNameInputField<ViewModel: TransactionFormStateProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var focusedField: FocusState<TransactionField?>.Binding
    let transactionType: TransactionType
    
    var body: some View {
        CustomTextField(
            hint: transactionType.nameFieldLabel,
            iconName: transactionType.nameFieldIcon,
            text: $viewModel.transactionName,
            keyboardType: .default,
            submitLabel: .next,
            textCapitalization: .words,
            onSubmit: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField.wrappedValue = .amount
                }
            },
            onChange: { _ in
                if viewModel.transactionName.count > 25 {
                    viewModel.transactionName = String(viewModel.transactionName.prefix(25))
                }
                viewModel.validateForm()
            },
            isFocused: focusedField.wrappedValue == .name
        )
        .focused(focusedField, equals: .name)
        .onTapGesture {
            if focusedField.wrappedValue != .name {
                focusedField.wrappedValue = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focusedField.wrappedValue = .name
                }
            }
        }
    }
}

struct TransactionAmountInputField<ViewModel: TransactionFormStateProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var focusedField: FocusState<TransactionField?>.Binding
    
    var body: some View {
        CustomTextField(
            hint: "Amount",
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

struct TransactionDateSelectorField<ViewModel: TransactionFormStateProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showingDatePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("Date")
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDateForDisplay)
                        .font(.appFont(14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.inputBorder, lineWidth: 1)
                )
            }
        }
    }
}

// Notes field for major expenses using protocol conformance instead of concrete types
struct TransactionNotesInputField<ViewModel: TransactionFormStateProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var focusedField: FocusState<TransactionField?>.Binding
    
    var body: some View {
        CustomTextField(
            hint: "Notes (Optional)",
            iconName: "note.text",
            text: $viewModel.notes,
            keyboardType: .default,
            submitLabel: .done,
            textCapitalization: .sentences,
            onSubmit: {
                focusedField.wrappedValue = nil
            },
            onChange: { _ in
                viewModel.validateForm()
            },
            isFocused: focusedField.wrappedValue == .notes
        )
        .focused(focusedField, equals: .notes)
    }
}

struct TransactionCategorySelectorField<CategoryType>: View where CategoryType: CategoryProtocol {
    let selectedCategory: CategoryType
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                onTap()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "triangle")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text("Category")
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(selectedCategory.displayName.uppercased())
                        .font(.appFont(14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.appFont(12))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.inputBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Action Buttons

// Save button that reads state and calls save on the action object
struct TransactionSaveButton<State: TransactionFormStateProtocol>: View {
    let viewModel: AnyAddAction<State>
    let transactionType: TransactionType
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.action.saveTransaction()
            }
        }) {
            HStack {
                if viewModel.state.isLoading {
                    ButtonProgressView()
                } else {
                    Text(transactionType.saveButtonText)
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
            viewModel.state.isFormValid && !viewModel.state.isLoading
                ? Color.primary
                : Color.gray.opacity(0.6)
        )
        .disabled(!viewModel.state.isFormValid || viewModel.state.isLoading)
        .padding(.top, 10)
    }
}

struct TransactionUpdateButton<State: TransactionFormStateProtocol>: View {
    let viewModel: AnyUpdateAction<State>
    let transactionType: TransactionType
    @Binding var showingUpdateAlert: Bool
    
    var body: some View {
        Button(action: {
            if viewModel.state.hasChanges {
                showingUpdateAlert = true
            } else {
                // Optional: show a feedback for no changes
            }
        }) {
            HStack {
                if viewModel.state.isLoading {
                    ButtonProgressView()
                } else {
                    Text(transactionType.updateButtonText)
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
            viewModel.state.isFormValid && !viewModel.state.isLoading
                ? Color.primary
                : Color.gray.opacity(0.6)
        )
        .disabled(!viewModel.state.isFormValid || !viewModel.state.hasChanges || viewModel.state.isLoading)
        .padding(.top, 10)
    }
}

// MARK: - Preview Support

class MockTransactionFormState: TransactionFormStateProtocol, AddTransactionActions, EditTransactionActions {
    @Published var transactionName: String = ""
    @Published var amountText: String = ""
    @Published var selectedDate: Date = Date()
    @Published var notes: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSuccess: Bool = false
    @Published var hasChanges: Bool = false
    
    var isFormValid: Bool {
        !transactionName.isEmpty && !amountText.isEmpty
    }
    
    var formattedDateForDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    var successMessage: String {
        "Transaction updated successfully!"
    }
    
    func loadInitialData() { }
    func validateForm() { }
    func resetForm() {
        transactionName = ""
        amountText = ""
        selectedDate = Date()
    }
    func clearError() { errorMessage = "" }
    
    func saveTransaction() async { }
    func updateTransaction() async { }
    func deleteTransaction() async { }
}

// MARK: - Previews

struct TransactionFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Add Expense Form - Light Mode
            NavigationView {
                TransactionFormView(
                    viewModel: MockTransactionFormState(),
                    transactionType: .expense,
                    mode: .add,
                    categories: ExpenseCategory.userSelectableCategories,
                    selectedCategory: ExpenseCategory.food,
                    onCategorySelected: { _ in }
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Add Expense - Light")
            
            // Add Expense Form - Dark Mode
            NavigationView {
                TransactionFormView(
                    viewModel: MockTransactionFormState(),
                    transactionType: .expense,
                    mode: .add,
                    categories: ExpenseCategory.userSelectableCategories,
                    selectedCategory: ExpenseCategory.food,
                    onCategorySelected: { _ in }
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Add Expense - Dark")
            
            // Update Income Form - Light Mode
            NavigationView {
                TransactionFormView(
                    viewModel: {
                        let vm = MockTransactionFormState()
                        vm.transactionName = "Salary"
                        vm.amountText = "50000"
                        return vm
                    }(),
                    transactionType: .income,
                    mode: .update,
                    categories: IncomeCategory.userSelectableCategories,
                    selectedCategory: IncomeCategory.salary,
                    onCategorySelected: { _ in }
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Update Income - Light")
            
            // Update Income Form - Dark Mode
            NavigationView {
                TransactionFormView(
                    viewModel: {
                        let vm = MockTransactionFormState()
                        vm.transactionName = "Salary"
                        vm.amountText = "50000"
                        return vm
                    }(),
                    transactionType: .income,
                    mode: .update,
                    categories: IncomeCategory.userSelectableCategories,
                    selectedCategory: IncomeCategory.salary,
                    onCategorySelected: { _ in }
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Update Income - Dark")
        }
    }
}

