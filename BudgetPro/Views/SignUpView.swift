import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
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
                            .font(.sora(32, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                        
                        Text("Sign up to get started")
                            .font(.sora(16))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 40)
                    
                    // Full Name input
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                            
                            TextField("Full Name", text: $viewModel.fullName)
                                .font(.sora(16))
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.words)
                                .focused($focusedField, equals: .fullName)
                                .onChange(of: viewModel.fullName) { _ in
                                    viewModel.validateFullName()
                                }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .fullName ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusedField == .fullName ? 2 : 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .fullName
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                            
                            TextField("Email", text: $viewModel.email)
                                .font(.sora(16))
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .onChange(of: viewModel.email) { _ in
                                    viewModel.validateEmail()
                                }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .email ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusedField == .email ? 2 : 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .email
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Password input
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                            
                            if viewModel.isPasswordVisible {
                                TextField("Password", text: $viewModel.password)
                                    .font(.sora(16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                    .focused($focusedField, equals: .password)
                                    .onChange(of: viewModel.password) { _ in
                                        viewModel.validatePassword()
                                    }
                            } else {
                                SecureField("Password", text: $viewModel.password)
                                    .font(.sora(16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                    .focused($focusedField, equals: .password)
                                    .onChange(of: viewModel.password) { _ in
                                        viewModel.validatePassword()
                                    }
                            }
                            
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .password ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusedField == .password ? 2 : 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .password
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Password strength indicator
                    if !viewModel.password.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password Strength:")
                                    .font(.sora(12))
                                    .foregroundColor(.gray)
                                
                                Text(viewModel.passwordStrength.text)
                                    .font(.sora(12, weight: .medium))
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
                                            .font(.sora(12))
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
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                            
                            if viewModel.isConfirmPasswordVisible {
                                TextField("Confirm Password", text: $viewModel.confirmPassword)
                                    .font(.sora(16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                    .focused($focusedField, equals: .confirmPassword)
                                    .onChange(of: viewModel.confirmPassword) { _ in
                                        viewModel.validateConfirmPassword()
                                    }
                            } else {
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .font(.sora(16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                    .focused($focusedField, equals: .confirmPassword)
                                    .onChange(of: viewModel.confirmPassword) { _ in
                                        viewModel.validateConfirmPassword()
                                    }
                            }
                            
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .confirmPassword ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusedField == .confirmPassword ? 2 : 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .confirmPassword
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.sora(14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Success message
                    if !viewModel.successMessage.isEmpty {
                        Text(viewModel.successMessage)
                            .font(.sora(14))
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
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign Up")
                                    .font(.sora(16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .frame(height: 50)
                    }
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isFormValid ? Color.secondary : Color.gray.opacity(0.6))
                    .cornerRadius(8)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .font(.sora(16))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Sign In")
                                .font(.sora(16, weight: .medium))
                                .foregroundColor(Color.secondary)
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

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
