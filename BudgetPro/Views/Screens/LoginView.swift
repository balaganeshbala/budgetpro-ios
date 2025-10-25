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
                        .font(.appFont(32, weight: .bold))
                        .foregroundColor(Color.primary)
                    
                    Text("Sign in to continue")
                        .font(.appFont(16))
                        .foregroundColor(.secondaryText)
                }
                .padding(.bottom, 60)
                .padding(.top, 60)
                
                // Email input
                CustomTextField(
                    hint: "Email",
                    iconName: "envelope",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    submitLabel: .next,
                    textCapitalization: .never,
                    onSubmit: {
                        focusField = .password
                    },
                    onChange: { _ in
                        viewModel.validateEmail()
                    },
                    isFocused: focusField == .email
                )
                .focused($focusField, equals: .email)
                .onTapGesture {
                    focusField = .email
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Password input (with show/hide)
                CustomTextField(
                    hint: "Password",
                    iconName: "lock",
                    text: $viewModel.password,
                    keyboardType: .default,
                    submitLabel: .done,
                    textCapitalization: .never,
                    onSubmit: {
                        focusField = nil
                        viewModel.signIn()
                    },
                    onChange: { _ in
                        viewModel.validatePassword()
                    },
                    isFocused: focusField == .password,
                    isSecure: !viewModel.isPasswordVisible
                ) {
                    Button(action: {
                        viewModel.togglePasswordVisibility()
                    }) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondaryText)
                            .padding(.trailing, 4)
                            .frame(height: 55)
                    }
                    .contentShape(Rectangle())
                }
                .focused($focusField, equals: .password)
                .onTapGesture {
                    focusField = .password
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.appFont(14))
                        .foregroundColor(.errorColor)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .multilineTextAlignment(.center)
                }
                
                // Sign In button
                Button(action: {
                    viewModel.signIn()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryText))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
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
                        ? Color.secondary
                        : Color.gray.opacity(0.6)
                )
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color.separator)
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.appFont(14))
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.separator)
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .font(.appFont(16))
                        .foregroundColor(.secondaryText)
                    
                    Button(action: {
                        viewModel.showSignUp(coordinator: coordinator)
                    }) {
                        Text("Sign Up")
                            .font(.appFont(16, weight: .medium))
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
        .background(Color.appBackground.ignoresSafeArea())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.light)
                .previewDisplayName("Login - Light")
            
            LoginView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Login - Dark")
        }
    }
}
