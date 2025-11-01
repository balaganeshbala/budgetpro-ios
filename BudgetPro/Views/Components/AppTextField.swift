//
//  AppTextField.swift
//  BudgetPro
//
//  Created by Balaganesh S on 31/10/25.
//

import SwiftUI

// MARK: - Reusable Floating Label Input Field

struct AppTextField<TrailingContent: View>: View {
    let hint: String
    let iconName: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let submitLabel: SubmitLabel
    let textCapitalization: TextInputAutocapitalization
    let onSubmit: () -> Void
    let onChange: (String) -> Void
    let isFocused: Bool
    let isSecure: Bool
    @ViewBuilder let trailingContent: () -> TrailingContent

    @FocusState private var isTextFieldFocused: Bool

    private var isLabelFloating: Bool {
        isFocused || !text.isEmpty
    }

    init(
        hint: String,
        iconName: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .done,
        textCapitalization: TextInputAutocapitalization = .never,
        onSubmit: @escaping () -> Void = {},
        onChange: @escaping (String) -> Void = { _ in },
        isFocused: Bool = false,
        isSecure: Bool = false,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() }
    ) {
        self.hint = hint
        self.iconName = iconName
        self._text = text
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
        self.textCapitalization = textCapitalization
        self.onSubmit = onSubmit
        self.onChange = onChange
        self.isFocused = isFocused
        self.isSecure = isSecure
        self.trailingContent = trailingContent
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(.secondaryText)
                    .font(.appFont(20))
                    .frame(width: 25, height: 25)
                
                ZStack(alignment: .leading) {
                    if isSecure {
                        SecureField(hint, text: $text)
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.primaryText)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(textCapitalization)
                            .submitLabel(submitLabel)
                            .focused($isTextFieldFocused)
                            .onSubmit(onSubmit)
                            .onChange(of: text, perform: onChange)
                            .frame(height: 55)
                    } else {
                        TextField(hint, text: $text)
                            .font(.appFont(16, weight: .medium))
                            .foregroundColor(.primaryText)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(textCapitalization)
                            .submitLabel(submitLabel)
                            .focused($isTextFieldFocused)
                            .onSubmit(onSubmit)
                            .onChange(of: text, perform: onChange)
                            .frame(height: 55)
                    }
                }
                
                // Trailing content, like visibility toggle button
                trailingContent()
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
    }
}

#Preview("AppTextField") {
    @State var sampleText = "John Doe"
    @State var passwordText = ""

    VStack(spacing: 24) {
        // Standard text field with no trailing content
        AppTextField(
            hint: "Full Name",
            iconName: "mail",
            text: $sampleText,
            keyboardType: .default,
            submitLabel: .next,
            textCapitalization: .words,
            onSubmit: { print("Submit: \(sampleText)") },
            onChange: { newText in print("Changed: \(newText)") },
            isFocused: false,
            isSecure: false
        )

        // Secure text field with a trailing visibility toggle button
        AppTextField(
            hint: "Password",
            iconName: "lock",
            text: $passwordText,
            keyboardType: .default,
            submitLabel: .done,
            textCapitalization: .never,
            onSubmit: { print("Submit: \(passwordText)") },
            onChange: { newText in print("Changed: \(newText)") },
            isFocused: false,
            isSecure: true
        ) {
            Button(action: {
                // Toggle password visibility (for preview this is a placeholder)
            }) {
                Image(systemName: "eye")
                    .foregroundColor(.gray)
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}
