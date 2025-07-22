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
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
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
                            .font(.system(size: 16, weight: .semibold))
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