import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Welcome!")
                            .font(.sora(20, weight: .bold))
                        
                        Text(viewModel.userEmail)
                            .font(.sora(14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showSignOutAlert()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "power")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding()
                
                Spacer()
                
                // Main content area
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .padding(.bottom, 20)
                    
                    Text("Authentication Complete!")
                        .font(.sora(24, weight: .bold))
                        .padding(.bottom, 10)
                    
                    Text("Welcome, \(viewModel.userDisplayName)!")
                        .font(.sora(20, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    Text("You are now signed in with Supabase")
                        .font(.sora(16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    VStack {
                        Text(viewModel.errorMessage)
                            .font(.sora(14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Dismiss") {
                            viewModel.dismissError()
                        }
                        .font(.sora(14))
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $viewModel.showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        viewModel.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
