//
//  CategoryFilterView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 28/09/25.
//

import SwiftUI

struct CategoryFilterView: View {
    let availableCategories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tempSelectedCategories: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with select all/none buttons
                headerSection
                
                Divider()
                
                // Categories list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(availableCategories.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                CategoryFilterRow(
                                    categoryName: availableCategories[index],
                                    isSelected: tempSelectedCategories.contains(availableCategories[index])
                                ) {
                                    toggleCategory(availableCategories[index])
                                }
                                
                                if index < availableCategories.count - 1 {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                    }
                }
                .background(Color.appBackground)
            }
            .navigationTitle("Filter Categories")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        selectedCategories = tempSelectedCategories
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempSelectedCategories = selectedCategories
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: selectAllCategories) {
                    Text("Select All")
                        .font(.sora(14, weight: .medium))
                        .foregroundColor(.adaptiveSecondary)
                }
                
                Spacer()
                
                Text("\(tempSelectedCategories.count) of \(availableCategories.count) selected")
                    .font(.sora(14))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Button(action: deselectAllCategories) {
                    Text("Clear All")
                        .font(.sora(14, weight: .medium))
                        .foregroundColor(.adaptiveSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func toggleCategory(_ categoryName: String) {
        if tempSelectedCategories.contains(categoryName) {
            tempSelectedCategories.remove(categoryName)
        } else {
            tempSelectedCategories.insert(categoryName)
        }
    }
    
    private func selectAllCategories() {
        tempSelectedCategories = Set(availableCategories)
    }
    
    private func deselectAllCategories() {
        tempSelectedCategories.removeAll()
    }
}

struct CategoryFilterRow: View {
    let categoryName: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var categoryInfo: ExpenseCategory {
        ExpenseCategory.from(categoryName: categoryName)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(categoryInfo.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryInfo.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(categoryInfo.color)
                )
            
            // Category name
            Text(categoryName)
                .font(.sora(16, weight: .medium))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Checkmark
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .adaptivePrimary : .secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct CategoryFilterView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryFilterView(
            availableCategories: ["Food", "Transport", "Entertainment", "Shopping", "Health/Beauty"],
            selectedCategories: .constant(Set(["Food", "Transport"]))
        )
        .preferredColorScheme(.dark)
    }
}
