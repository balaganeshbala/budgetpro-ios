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
            .background(Color.gray.opacity(0.1))
            .navigationTitle("About BudgetPro")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.sora(16, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
            )
        }
        .onAppear {
            loadAppVersion()
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            // App Icon
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            // App Name and Version
            VStack(spacing: 8) {
                Text("BudgetPro")
                    .font(.sora(24, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Version \(appVersion)")
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
    
    // MARK: - App Description Section
    private var appDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("BudgetPro is a comprehensive personal finance application designed to help you manage budgets, track expenses & incomes, and achieve your financial goals.")
                .font(.sora(14))
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            Text("Take control of your finances with intuitive tools for budget planning, expense tracking, and financial insights.")
                .font(.sora(14))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Features")
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
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
                    iconColor: Color(red: 0.2, green: 0.6, blue: 0.5),
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Developer Section
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Developer")
                .font(.sora(18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Built with ❤️ using SwiftUI and Supabase")
                .font(.sora(14))
                .foregroundColor(.gray)
            
            Text("© 2025 BudgetPro. All rights reserved.")
                .font(.sora(12))
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 1)
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
        HStack(spacing: 12) {
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
                    .font(.sora(14, weight: .medium))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.sora(12))
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
