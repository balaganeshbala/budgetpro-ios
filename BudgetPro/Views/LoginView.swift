import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var coordinator: AuthenticationCoordinator
    @FocusState private var focusField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Welcome text
                VStack(spacing: 8) {
                    Text("Welcome Back!")
                        .font(.sora(32, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                    
                    Text("Sign in to continue")
                        .font(.sora(16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 60)
                .padding(.top, 60)
                
                // Email input
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                        
                        TextField("Email", text: $viewModel.email)
                            .font(.sora(16))
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .focused($focusField, equals: .email)
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
                            .stroke(focusField == .email ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusField == .email ? 2 : 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusField = .email
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Password input
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                        
                        if viewModel.isPasswordVisible {
                            TextField("Password", text: $viewModel.password)
                                .font(.sora(16))
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($focusField, equals: .password)
                                .onChange(of: viewModel.password) { _ in
                                    viewModel.validatePassword()
                                }
                        } else {
                            SecureField("Password", text: $viewModel.password)
                                .font(.sora(16))
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($focusField, equals: .password)
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
                            .stroke(focusField == .password ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color.gray.opacity(0.3), lineWidth: focusField == .password ? 2 : 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusField = .password
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
                
                // Sign In button
                Button(action: {
                    viewModel.signIn()
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
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
                
                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.sora(14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .font(.sora(16))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        viewModel.showSignUp(coordinator: coordinator)
                    }) {
                        Text("Sign Up")
                            .font(.sora(16, weight: .medium))
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .contentShape(Rectangle())
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
