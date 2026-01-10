//
//  SettingsViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/01/26.
//

import LocalAuthentication
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("isBiometricEnabled") var isBiometricEnabled = false {
        didSet {
            // If turning ON, verify we can actually use biometrics
            if isBiometricEnabled && !oldValue {
                verifyBiometricCapability()
            }
        }
    }
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("lockTimeout") var lockTimeout: LockTimeout = .immediately
    
    @Published var biometricIcon: String = "faceid"
    @Published var biometricColor: Color = .green
    
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    init() {
        decideBiometricType()
    }
    
    func deleteAccount() {
        isDeleting = true
        Task {
            do {
                try await SupabaseManager.shared.deleteAccount()
                // Successful deletion will trigger signOut, which updates AppCoordinator
                // No need to manually navigate
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isDeleting = false
                }
            }
        }
    }
    
    private func decideBiometricType() {
        let context = LAContext()
        if (context.biometryType == .touchID) {
            biometricIcon = "touchid"
            biometricColor = .red
        } else if (context.biometryType == .faceID) {
            biometricIcon = "faceid"
            biometricColor = .green
        }
    }
    
    private func verifyBiometricCapability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Verify identity to enable biometric lock."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if !success {
                        // Failed to authenticate or declined permission, revert toggle
                        self?.isBiometricEnabled = false
                    }
                }
            }
        } else {
            // Not capable/available
            isBiometricEnabled = false
        }
    }
}
