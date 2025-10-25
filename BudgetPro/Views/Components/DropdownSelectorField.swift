//
//  DropdownSelectorField.swift
//  BudgetPro
//
//  Created by Balaganesh Balaganesh on 10/10/25.
//

import SwiftUI

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
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    if let selectedItem = selectedItem {
                        Text(itemDisplayName(selectedItem).uppercased())
                            .font(.appFont(14, weight: .semibold))
                            .foregroundColor(Color.primary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.appFont(12))
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
