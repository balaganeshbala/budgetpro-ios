//
//  AboutView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var appVersion = "1.0.0"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    appInfoSection
                    
                    // App Description
                    appDescriptionSection
                    
                    // Features Section
                    featuresSection
                    
                    // Developer Info
                    developerSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(Color.groupedBackground)
            .navigationTitle("About Budget Pro")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.appFont(16, weight: .medium))
                .foregroundColor(.secondary)
            )
        }
        .onAppear {
            loadAppVersion()
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        CardView(padding: EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16)) {
            VStack(spacing: 16) {
                
                Image("IconRounded")
                    .resizable()
                    .frame(width: 80, height: 80)
                
                // App Name
                Text("Budget")
                    .font(.appFont(24, weight: .bold))
                    .foregroundColor(.primary)
                +
                Text(" Pro")
                    .font(.appFont(24, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text("Version \(appVersion)")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - App Description Section
    private var appDescriptionSection: some View {
        CardView(padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Budget Pro is a comprehensive personal finance application designed to help you manage budgets, track expenses & incomes, and achieve your financial goals.")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                    .lineSpacing(4)
                
                Text("Take control of your finances with intuitive tools for budget planning, expense tracking, and financial insights.")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        CardView(padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Key Features")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 20) {
                    FeatureRow(
                        icon: "chart.pie",
                        iconColor: Color.secondary,
                        title: "Budget Management",
                        description: "Create and track monthly budgets by category"
                    )
                    
                    FeatureRow(
                        icon: "creditcard",
                        iconColor: .orange,
                        title: "Expense Tracking",
                        description: "Record and categorize your daily expenses"
                    )
                    
                    FeatureRow(
                        icon: "plus.circle",
                        iconColor: .primary,
                        title: "Income Management",
                        description: "Track multiple income sources and earnings"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .purple,
                        title: "Financial Insights",
                        description: "Analyze spending patterns and savings"
                    )
                    
                    FeatureRow(
                        icon: "calendar",
                        iconColor: .blue,
                        title: "Monthly Overview",
                        description: "View financial data by month and year"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Developer Section
    private var developerSection: some View {
        CardView(padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Developer")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("Built with ❤️ using SwiftUI and Supabase")
                    .font(.appFont(14))
                    .foregroundColor(.secondaryText)
                
                Text("© 2025 BudgetPro. All rights reserved.")
                    .font(.appFont(12))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Helper Methods
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appFont(14, weight: .medium))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.appFont(12))
                    .foregroundColor(.secondaryText)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
