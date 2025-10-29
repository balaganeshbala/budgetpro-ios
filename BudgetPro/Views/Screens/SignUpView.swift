import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject private var coordinator: AuthenticationCoordinator
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Welcome text
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.appFont(32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign up to get started")
                            .font(.appFont(16))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 40)
                    
                    // Full Name input
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            hint: "Full Name",
                            iconName: "person",
                            text: $viewModel.fullName,
                            keyboardType: .default,
                            submitLabel: .next,
                            textCapitalization: .words,
                            onSubmit: {
                                focusedField = .email
                            },
                            onChange: { _ in
                                viewModel.validateFullName()
                            },
                            isFocused: focusedField == .fullName
                        )
                        .focused($focusedField, equals: .fullName)
                        .onTapGesture {
                            focusedField = .fullName
                        }
                        
                        if !viewModel.fullNameError.isEmpty {
                            Text(viewModel.fullNameError)
                                .font(.appFont(12))
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            hint: "Email",
                            iconName: "envelope",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            submitLabel: .next,
                            textCapitalization: .never,
                            onSubmit: {
                                focusedField = .password
                            },
                            onChange: { _ in
                                viewModel.validateEmail()
                            },
                            isFocused: focusedField == .email
                        )
                        .focused($focusedField, equals: .email)
                        .onTapGesture {
                            focusedField = .email
                        }
                        
                        if !viewModel.emailError.isEmpty {
                            Text(viewModel.emailError)
                                .font(.appFont(12))
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Password input
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            hint: "Password",
                            iconName: "lock",
                            text: $viewModel.password,
                            keyboardType: .default,
                            submitLabel: .next,
                            textCapitalization: .never,
                            onSubmit: {
                                focusedField = .confirmPassword
                            },
                            onChange: { _ in
                                viewModel.validatePassword()
                            },
                            isFocused: focusedField == .password,
                            isSecure: !viewModel.isPasswordVisible
                        ) {
                            Button(action: {
                                viewModel.togglePasswordVisibility()
                            }) {
                                Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                            }
                            .contentShape(Rectangle())
                        }
                        .focused($focusedField, equals: .password)
                        .onTapGesture {
                            focusedField = .password
                        }
                        
                        if !viewModel.passwordError.isEmpty {
                            Text(viewModel.passwordError)
                                .font(.appFont(12))
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Password strength indicator
                    if !viewModel.password.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password Strength:")
                                    .font(.appFont(12))
                                    .foregroundColor(.gray)
                                
                                Text(viewModel.passwordStrength.text)
                                    .font(.appFont(12, weight: .medium))
                                    .foregroundColor(viewModel.passwordStrength.color)
                                
                                Spacer()
                            }
                            
                            // Password requirements checklist
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.passwordRequirements, id: \.text) { requirement in
                                    HStack(spacing: 8) {
                                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(requirement.isMet ? .green : .gray)
                                            .font(.system(size: 12))
                                        
                                        Text(requirement.text)
                                            .font(.appFont(12))
                                            .foregroundColor(requirement.isMet ? .green : .gray)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // Confirm Password input
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            hint: "Confirm Password",
                            iconName: "lock.fill",
                            text: $viewModel.confirmPassword,
                            keyboardType: .default,
                            submitLabel: .done,
                            textCapitalization: .never,
                            onSubmit: {
                                focusedField = nil
                                signUp()
                            },
                            onChange: { _ in
                                viewModel.validateConfirmPassword()
                            },
                            isFocused: focusedField == .confirmPassword,
                            isSecure: !viewModel.isConfirmPasswordVisible
                        ) {
                            Button(action: {
                                viewModel.toggleConfirmPasswordVisibility()
                            }) {
                                Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                            }
                            .contentShape(Rectangle())
                        }
                        .focused($focusedField, equals: .confirmPassword)
                        .onTapGesture {
                            focusedField = .confirmPassword
                        }
                        
                        if !viewModel.confirmPasswordError.isEmpty {
                            Text(viewModel.confirmPasswordError)
                                .font(.appFont(12))
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.appFont(14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Success message
                    if !viewModel.successMessage.isEmpty {
                        Text(viewModel.successMessage)
                            .font(.appFont(14))
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Sign Up button
                    Button(action: {
                        signUp()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ButtonProgressView()
                            } else {
                                Text("Sign Up")
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
                        viewModel.isFormValid && !viewModel.isLoading
                            ? Color.primary
                            : Color.gray.opacity(0.6)
                    )
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .font(.appFont(16))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Sign In")
                                .font(.appFont(16, weight: .medium))
                                .foregroundColor(Color.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .contentShape(Rectangle())
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func signUp() {
        Task {
            let success = await viewModel.signUp()
            if success {
                // Dismiss after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct SignUpViewLight_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.light)
    }
}

struct SignUpViewDark_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.dark)
    }
}
