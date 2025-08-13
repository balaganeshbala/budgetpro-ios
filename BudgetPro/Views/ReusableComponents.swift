//
//  ReusableComponents.swift
//  BudgetPro
//
//  Created by Balaganesh S on 20/07/25.
//

import SwiftUI

// MARK: - Reusable Floating Label Input Field

struct CustomTextField: View {
    let hint: String
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
                    .foregroundColor(.secondaryText)
                    .font(.sora(_: 20))
                
                TextField(hint, text: $text)
                    .font(.sora(_: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(textCapitalization)
                    .submitLabel(submitLabel)
                    .focused($isTextFieldFocused)
                    .onSubmit(onSubmit)
                    .onChange(of: text, perform: onChange)
                    .frame(height: 55)
            }
            .padding(.horizontal, 16)
            .background(Color.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((isFocused || isTextFieldFocused) ? Color.focusedInputBorder : Color.inputBorder, lineWidth: (isFocused || isTextFieldFocused) ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .onTapGesture {
            isTextFieldFocused = true
        }
        .onChange(of: isFocused) { newValue in
            isTextFieldFocused = newValue
        }
        .onChange(of: isTextFieldFocused) { newValue in
            if !newValue {
                // Only call onSubmit when focus is lost, not when gained
            }
        }
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
                    .font(.sora(_: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 180)
                
                HStack(spacing: 20) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.sora(_: 16, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.secondarySystemFill)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.sora(_: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(24)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

// MARK: - Generic Dropdown Picker Dialog

struct DropdownPickerDialog<T: Hashable>: View {
    let title: String
    let items: [T]
    let selectedItem: T?
    let onItemSelected: (T) -> Void
    let itemDisplayName: (T) -> String
    let itemIcon: ((T) -> String)?
    let itemColor: ((T) -> Color)?
    @Binding var isPresented: Bool
    
    init(
        title: String,
        items: [T],
        selectedItem: T?,
        onItemSelected: @escaping (T) -> Void,
        itemDisplayName: @escaping (T) -> String,
        itemIcon: ((T) -> String)? = nil,
        itemColor: ((T) -> Color)? = nil,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.items = items
        self.selectedItem = selectedItem
        self.onItemSelected = onItemSelected
        self.itemDisplayName = itemDisplayName
        self.itemIcon = itemIcon
        self.itemColor = itemColor
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Picker content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(.sora(20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Items list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items, id: \.self) { item in
                            HStack(spacing: 16) {
                                // Icon (if provided)
                                if let itemIcon = itemIcon {
                                    Image(systemName: itemIcon(item))
                                        .foregroundColor(itemColor?(item) ?? .secondaryText)
                                        .font(.system(size: 20))
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text(itemDisplayName(item))
                                    .font(.sora(16, weight: .medium))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                // Checkmark for selected item
                                if let selectedItem = selectedItem, selectedItem == item {
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
                                onItemSelected(item)
                                isPresented = false
                            }
                            
                            // Divider (except for last item)
                            if item != items.last {
                                Divider()
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color.cardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Generic Dropdown Selector Field

enum GenericFormField {
    case name
    case amount
}

struct DropdownSelectorField<T: Hashable>: View {
    let label: String
    let iconName: String
    let selectedItem: T?
    let itemDisplayName: (T) -> String
    let onTap: () -> Void
    let focusedField: FocusState<GenericFormField?>.Binding?
    
    init(
        label: String,
        iconName: String,
        selectedItem: T?,
        itemDisplayName: @escaping (T) -> String,
        onTap: @escaping () -> Void,
        focusedField: FocusState<GenericFormField?>.Binding? = nil
    ) {
        self.label = label
        self.iconName = iconName
        self.selectedItem = selectedItem
        self.itemDisplayName = itemDisplayName
        self.onTap = onTap
        self.focusedField = focusedField
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                // Dismiss keyboard if focusedField is provided
                focusedField?.wrappedValue = nil
                // Execute tap action
                onTap()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .foregroundColor(.secondaryText)
                        .font(.system(size: 20))
                    
                    Text(label)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    if let selectedItem = selectedItem {
                        Text(itemDisplayName(selectedItem).uppercased())
                            .font(.sora(14, weight: .semibold))
                            .foregroundColor(Color.primary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.sora(12))
                        .foregroundColor(Color.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.secondarySystemFill)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
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

// MARK: - Budget Overview Card Component

struct BudgetOverviewCard: View {
    let title: String
    let totalBudget: Double
    let totalSpent: Double
    let showEditButton: Bool
    let showDetailsButton: Bool
    let onEditTapped: (() -> Void)?
    let onDetailsTapped: (() -> Void)?
    
    init(
        title: String = "Budget Overview",
        totalBudget: Double,
        totalSpent: Double,
        showEditButton: Bool = false,
        showDetailsButton: Bool = false,
        onEditTapped: (() -> Void)? = nil,
        onDetailsTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.totalBudget = totalBudget
        self.totalSpent = totalSpent
        self.showEditButton = showEditButton
        self.showDetailsButton = showDetailsButton
        self.onEditTapped = onEditTapped
        self.onDetailsTapped = onDetailsTapped
    }
    
    private var remainingBudget: Double {
        totalBudget - totalSpent
    }
    
    private var isOverBudget: Bool {
        totalSpent > totalBudget
    }
    
    private var usagePercentage: Int {
        Int((totalSpent / max(totalBudget, 1)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.sora(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if showEditButton {
                    Button(action: {
                        onEditTapped?()
                    }) {
                        Label {
                            Text("Edit")
                                .font(.sora(14, weight: .semibold))
                        } icon: {
                            if #available(iOS 16.0, *) {
                                Image(systemName: "pencil")
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "pencil")
                            }
                        }
                        .foregroundColor(.adaptiveSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.adaptiveSecondary.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
            }
            
            // Budget content
            VStack(spacing: 20) {
                // Remaining Amount - Highlighted at the top
                VStack(alignment: .center, spacing: 8) {
                    Text("Remaining Budget")
                        .font(.sora(18, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text("₹\(CommonHelpers.formatAmount(max(0, remainingBudget)))")
                        .font(.sora(30, weight: .bold))
                        .foregroundColor(isOverBudget ? .overBudgetColor : .adaptivePrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isOverBudget ? Color.overBudgetColor.opacity(0.05) : Color.adaptivePrimary.opacity(0.05),
                            isOverBudget ? Color.overBudgetColor.opacity(0.1) : Color.adaptivePrimary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isOverBudget ? Color.overBudgetColor.opacity(0.2) : Color.adaptivePrimary.opacity(0.2), lineWidth: 1)
                )
                
                // Budget Summary Row
                HStack(spacing: 16) {
                    // Total Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.sora(14))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(CommonHelpers.formatAmount(totalBudget))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Total Spent
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Spent")
                            .font(.sora(14))
                            .foregroundColor(.secondaryText)
                        
                        Text("₹\(CommonHelpers.formatAmount(totalSpent))")
                            .font(.sora(20, weight: .semibold))
                            .foregroundColor(isOverBudget ? .overBudgetColor : .warningColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Progress Bar with Percentage
                if totalBudget > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Budget Usage")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Text("\(usagePercentage)%")
                                .font(.sora(16, weight: .bold))
                                .foregroundColor(isOverBudget ? .overBudgetColor : .warningColor)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondarySystemFill)
                                    .frame(height: 10)
                                    .cornerRadius(5)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                isOverBudget ? Color.overBudgetColor : Color.warningColor,
                                                isOverBudget ? Color.overBudgetColor.opacity(0.8) : Color.warningColor.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: min(geometry.size.width, geometry.size.width * (totalSpent / max(totalBudget, 1))), height: 10)
                                    .cornerRadius(5)
                                    .animation(.easeInOut(duration: 0.5), value: totalSpent)
                            }
                        }
                        .frame(height: 10)
                    }
                }
                
                // Details Button
                if showDetailsButton {
                    Button(action: {
                        onDetailsTapped?()
                    }) {
                        HStack {
                            Text("View Budget Details")
                                .font(.sora(14, weight: .medium))
                                .foregroundColor(.adaptiveSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.adaptiveSecondary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

// MARK: - UINavigationController Extension for enabling Interactive Pop Gesture
extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
