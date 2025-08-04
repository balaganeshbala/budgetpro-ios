//
//  TransactionFormView.swift
//  BudgetPro
//
//  Created by Claude on 02/08/25.
//

import SwiftUI

// MARK: - Transaction Type Enum
enum TransactionType {
    case expense
    case income
    
    var title: String {
        switch self {
        case .expense: return "Expense Details"
        case .income: return "Income Details"
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .expense: return "Add Expense"
        case .income: return "Add Income"
        }
    }
    
    var updateNavigationTitle: String {
        switch self {
        case .expense: return "Update Expense"
        case .income: return "Update Income"
        }
    }
    
    var nameFieldLabel: String {
        switch self {
        case .expense: return "Expense Name"
        case .income: return "Income Source"
        }
    }
    
    var nameFieldIcon: String {
        switch self {
        case .expense: return "bag"
        case .income: return "dollarsign.circle"
        }
    }
    
    var saveButtonText: String {
        switch self {
        case .expense: return "Save Expense"
        case .income: return "Save Income"
        }
    }
    
    var updateButtonText: String {
        switch self {
        case .expense: return "Update Expense"
        case .income: return "Update Income"
        }
    }
    
    var loadingText: String {
        switch self {
        case .expense: return "Adding expense..."
        case .income: return "Adding income..."
        }
    }
    
    var updateLoadingText: String {
        switch self {
        case .expense: return "Updating expense..."
        case .income: return "Updating income..."
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

// MARK: - Transaction Form View Model Protocol
@MainActor
protocol TransactionFormViewModelProtocol: ObservableObject {
    var transactionName: String { get set }
    var amountText: String { get set }
    var selectedDate: Date { get set }
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
    func saveTransaction() async
    func updateTransaction() async
    func deleteTransaction() async
    func clearError()
}

// MARK: - Transaction Field Enum
enum TransactionField {
    case name
    case amount
}

// MARK: - Generic Transaction Form View
struct TransactionFormView<ViewModel: TransactionFormViewModelProtocol, CategoryType: Hashable>: View {
    @StateObject private var viewModel: ViewModel
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
    let categoryDisplayName: (CategoryType) -> String
    let categoryIconName: (CategoryType) -> String
    let categoryColor: (CategoryType) -> Color
    
    init(
        viewModel: @autoclosure @escaping () -> ViewModel,
        transactionType: TransactionType,
        mode: TransactionFormMode,
        categories: [CategoryType],
        selectedCategory: CategoryType,
        onCategorySelected: @escaping (CategoryType) -> Void,
        categoryDisplayName: @escaping (CategoryType) -> String,
        categoryIconName: @escaping (CategoryType) -> String,
        categoryColor: @escaping (CategoryType) -> Color
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.transactionType = transactionType
        self.mode = mode
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.onCategorySelected = onCategorySelected
        self.categoryDisplayName = categoryDisplayName
        self.categoryIconName = categoryIconName
        self.categoryColor = categoryColor
    }
    
    // MARK: - Computed Properties
    private var navigationTitle: String {
        mode.isUpdate ? transactionType.updateNavigationTitle : transactionType.navigationTitle
    }
    
    
    private var mainContent: some View {
        ZStack {
            formScrollView
            
            if viewModel.isLoading {
                TransactionLoadingOverlay(
                    transactionType: transactionType,
                    mode: mode
                )
            }
        }
    }
    
    private var formScrollView: some View {
        ScrollView {
            Color.clear
                .frame(height: 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            
            formContentCard
        }
    }
    
    private var formContentCard: some View {
        VStack(spacing: 24) {
            titleSection
            formFields
            actionButton
            Spacer(minLength: 30)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: UIScreen.main.bounds.height - 150)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var titleSection: some View {
        HStack {
            Text(transactionType.title)
                .font(.sora(20, weight: .semibold))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.top, 24)
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
                categoryDisplayName: categoryDisplayName,
                onTap: { showingCategoryPicker = true }
            )
            
            TransactionDateSelectorField(
                viewModel: viewModel,
                showingDatePicker: $showingDatePicker
            )
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if mode.isUpdate {
            TransactionUpdateButton(
                viewModel: viewModel,
                transactionType: transactionType,
                showingUpdateAlert: $showingUpdateAlert
            )
        } else {
            TransactionSaveButton(
                viewModel: viewModel,
                transactionType: transactionType,
                dismiss: dismiss
            )
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
                    if mode.isUpdate {
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
            itemDisplayName: categoryDisplayName,
            itemIcon: categoryIconName,
            itemColor: categoryColor,
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
        Button("Delete", role: .destructive) {
            Task {
                await viewModel.deleteTransaction()
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
        Button("Update") {
            Task {
                await viewModel.updateTransaction()
            }
        }
    }
    
    @ViewBuilder
    private func updateAlertMessage() -> some View {
        Text("Are you sure you want to update this \(transactionName.lowercased())?")
    }
    
    // MARK: - Action Handlers
    private func handleViewAppear() {
        configureNavigationBar()
        viewModel.loadInitialData()
    }
    
    private func navigateToRoot() {
        // Find the navigation controller and pop to root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the navigation controller in the hierarchy
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
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.label
    }
}

// MARK: - Input Fields

struct TransactionNameInputField<ViewModel: TransactionFormViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var focusedField: FocusState<TransactionField?>.Binding
    let transactionType: TransactionType
    
    var body: some View {
        FloatingLabelTextField(
            label: transactionType.nameFieldLabel,
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

struct TransactionAmountInputField<ViewModel: TransactionFormViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var focusedField: FocusState<TransactionField?>.Binding
    
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

struct TransactionDateSelectorField<ViewModel: TransactionFormViewModelProtocol>: View {
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

struct TransactionCategorySelectorField<CategoryType>: View where CategoryType: Hashable {
    let selectedCategory: CategoryType
    let categoryDisplayName: (CategoryType) -> String
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
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(categoryDisplayName(selectedCategory).uppercased())
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

// MARK: - Action Buttons

struct TransactionSaveButton<ViewModel: TransactionFormViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let transactionType: TransactionType
    let dismiss: DismissAction
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.saveTransaction()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(transactionType.saveButtonText)
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                    ? Color.secondary
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.top, 24)
    }
}

struct TransactionUpdateButton<ViewModel: TransactionFormViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let transactionType: TransactionType
    @Binding var showingUpdateAlert: Bool
    
    var body: some View {
        Button(action: {
            if viewModel.hasChanges {
                showingUpdateAlert = true
            } else {
                // Handle no changes case - you might want to show an error
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(transactionType.updateButtonText)
                        .font(.sora(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                viewModel.isFormValid && viewModel.hasChanges && !viewModel.isLoading
                    ? Color.secondary
                    : Color.gray.opacity(0.6)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || !viewModel.hasChanges || viewModel.isLoading)
        .padding(.top, 24)
    }
}

// MARK: - Loading Overlay

struct TransactionLoadingOverlay: View {
    let transactionType: TransactionType
    let mode: TransactionFormMode
    
    var body: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.secondary))
                        .scaleEffect(1.5)
                    
                    Text(mode.isUpdate ? transactionType.updateLoadingText : transactionType.loadingText)
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
