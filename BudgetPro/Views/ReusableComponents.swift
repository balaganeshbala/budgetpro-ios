//
//  ReusableComponents.swift
//  BudgetPro
//
//  Created by Balaganesh S on 20/07/25.
//

import SwiftUI

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
                    .font(.sora(_: 20))
                
                TextField("", text: $text)
                    .font(.sora(_: 16, weight: .medium))
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
                .font(.sora(_: isLabelFloating ? 12 : 16, weight: .medium))
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
                    .foregroundColor(.black)
                
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
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.gray.opacity(0.1))
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
                            .background(Color(red: 0.2, green: 0.6, blue: 0.5))
                            .cornerRadius(8)
                    }
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
                
                // Items list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items, id: \.self) { item in
                            HStack(spacing: 16) {
                                // Icon (if provided)
                                if let itemIcon = itemIcon {
                                    Image(systemName: itemIcon(item))
                                        .foregroundColor(itemColor?(item) ?? .gray)
                                        .font(.system(size: 20))
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text(itemDisplayName(item))
                                    .font(.sora(16, weight: .medium))
                                    .foregroundColor(.black)
                                
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
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Generic Dropdown Selector Field

struct DropdownSelectorField<T: Hashable>: View {
    let label: String
    let iconName: String
    let selectedItem: T?
    let itemDisplayName: (T) -> String
    let onTap: () -> Void
    let focusedField: FocusState<AddExpenseView.Field?>.Binding?
    
    init(
        label: String,
        iconName: String,
        selectedItem: T?,
        itemDisplayName: @escaping (T) -> String,
        onTap: @escaping () -> Void,
        focusedField: FocusState<AddExpenseView.Field?>.Binding? = nil
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
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                    
                    Text(label)
                        .font(.sora(16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let selectedItem = selectedItem {
                        Text(itemDisplayName(selectedItem).uppercased())
                            .font(.sora(14, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                    }
                    
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

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }
}
