//
//  ProfileView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var coordinator: MainCoordinator
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSignOutAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Info Card
                userInfoCard
                
                // Settings Options
                settingsOptionsCard
                
                // General Options
                generalOptionsCard
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .disableScrollViewBounce()
        .background(Color.groupedBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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
        CardView(padding: EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16)) {
            VStack(spacing: 16) {
                // Profile Avatar
                Circle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.primary)
                    )
                
                VStack(spacing: 8) {
                    // User Name
                    Text(viewModel.userName)
                        .font(.appFont(20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    // User Email
                    Text(viewModel.userEmail)
                        .font(.appFont(14))
                        .foregroundColor(.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Settings Options Card
    private var settingsOptionsCard: some View {
        CardView(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                // Financial Goals Button
                SettingsRow(
                    icon: "target",
                    iconColor: .purple,
                    title: "Financial Goals",
                    showChevron: true
                ) {
                    coordinator.navigate(to: .financialGoals)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Major Expenses Button
                SettingsRow(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    iconColor: .orange,
                    title: "Major Expenses",
                    showChevron: true
                ) {
                    coordinator.navigate(to: .allMajorExpenses)
                }
            }
        }
    }
    
    // MARK: - General Options Card
    private var generalOptionsCard: some View {
        CardView(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                 // Settings Button
                SettingsRow(
                    icon: "gear",
                    iconColor: .gray,
                    title: "Settings",
                    showChevron: true
                ) {
                    coordinator.navigate(to: .settings)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // About Button
                SettingsRow(
                    icon: "info.circle",
                    iconColor: .blue,
                    title: "About Budget Pro",
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
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color?
    let title: String
    let showChevron: Bool
    let action: () -> Void

    // Custom initializer to make backgroundColor optional at call sites
    init(
        icon: String,
        iconColor: Color,
        backgroundColor: Color? = nil,
        title: String,
        showChevron: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.title = title
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                RowItemIcon(categoryIcon: icon,
                            iconShape: .circle,
                            iconColor: iconColor,
                            backgroundColor: backgroundColor)
                
                // Title
                Text(title)
                    .font(.appFont(16))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
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
