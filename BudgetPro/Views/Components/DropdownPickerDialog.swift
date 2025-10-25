//
//  DropdownPickerDialog.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/10/25.
//

import SwiftUI

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
            Color.overlayBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Picker content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(.appFont(20, weight: .semibold))
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
                                    .font(.appFont(16, weight: .medium))
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
