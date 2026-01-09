//
//  SettingsView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/01/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: MainCoordinator
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            
            Color.groupedBackground
                .ignoresSafeArea(.all)
            
            Form {
                Section {
                    Toggle(isOn: $viewModel.isBiometricEnabled) {
                        Label {
                            Text("Biometric Screen Lock")
                                .font(.appFont(16))
                                .foregroundColor(.primaryText)
                        } icon: {
                            Image(systemName: viewModel.biometricIcon)
                                .foregroundColor(viewModel.biometricColor)
                        }
                    }
                    
                    if viewModel.isBiometricEnabled {
                        Picker(selection: $viewModel.lockTimeout) {
                            ForEach(LockTimeout.allCases) { timeout in
                                Text(timeout.rawValue).tag(timeout)
                            }
                        } label: {
                            Label {
                                Text("Lock App")
                                    .font(.appFont(16))
                                    .foregroundColor(.primaryText)
                            } icon: {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Security")
                }
                .listRowBackground(Color.cardBackground)
                
                Section {
                    Picker(selection: $viewModel.appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    } label: {
                        Label {
                            Text("App Theme")
                                .font(.appFont(16))
                                .foregroundColor(.primaryText)
                        } icon: {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.purple)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                .listRowBackground(Color.cardBackground)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.light)
    }
}
