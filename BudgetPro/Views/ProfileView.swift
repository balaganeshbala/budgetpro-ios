//
//  ProfileView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSignOutAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Info Card
                    userInfoCard
                    
                    // Settings Options
                    settingsOptionsCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.sora(16, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
            )
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .onAppear {
            viewModel.loadUserInfo()
        }
    }
    
    // MARK: - User Info Card
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // Profile Avatar
            Circle()
                .fill(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                )
            
            VStack(spacing: 8) {
                // User Name
                Text(viewModel.userName)
                    .font(.sora(20, weight: .semibold))
                    .foregroundColor(.black)
                
                // User Email
                Text(viewModel.userEmail)
                    .font(.sora(14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Settings Options Card
    private var settingsOptionsCard: some View {
        VStack(spacing: 0) {
            // About Button
            SettingsRow(
                icon: "info.circle",
                iconColor: .blue,
                title: "About BudgetPro",
                showChevron: true
            ) {
                showingAbout = true
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Sign Out Button
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: .red,
                title: "Sign Out",
                showChevron: false
            ) {
                showingSignOutAlert = true
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(iconColor)
                    )
                
                // Title
                Text(title)
                    .font(.sora(16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(16)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
