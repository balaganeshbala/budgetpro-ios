//
//  AppLockViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/01/26.
//

import SwiftUI
import LocalAuthentication

class AppLockViewModel: ObservableObject {
    @Published var isLocked = false
    @Published var isAuthenticating = false
    @AppStorage("isBiometricEnabled") var isBiometricEnabled = false
    
    // State to track if we should automatically prompt for biometrics
    // This prevents the loop where cancelling the prompt immediately triggers it again
    private var allowAutoAuthentication = true
    
    // Track when the app entered background
    private var backgroundEntryTime: Date?
    
    @AppStorage("lockTimeout") private var lockTimeout: LockTimeout = .immediately
    
    init() {
        if isBiometricEnabled {
            isLocked = true
        }
    }
    
    /// Called when the app becomes active or scene phase changes
    func checkUnlockPolicy() {
        // If biometric is disabled, ensure we are unlocked
        guard isBiometricEnabled else {
            isLocked = false
            return
        }
        
        // If not locked, do nothing
        guard isLocked else { return }
        
        // Check timeout
        if let entryTime = backgroundEntryTime {
            let elapsed = Date().timeIntervalSince(entryTime)
            if elapsed < lockTimeout.timeInterval {
                // Within timeout, unlock without auth
                isLocked = false
                return
            }
        }
        
        // Timeout exceeded or immediate lock, attempt auth
        attemptAutoUnlock()
    }
    
    private func attemptAutoUnlock() {
        guard allowAutoAuthentication else { return }
        authenticate(manual: false)
    }
    
    /// Called when the user manually taps the Unlock button
    func manualAuthenticate() {
        authenticate(manual: true)
    }
    
    private func authenticate(manual: Bool) {
        guard !isAuthenticating else { return }
        guard isLocked else { return }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAuthenticating = true
            let reason = "Unlock your data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    
                    if success {
                        self?.isLocked = false
                        self?.allowAutoAuthentication = true
                    } else {
                        print("Authentication failed")
                        // If this was an auto-attempt and it failed/cancelled, stop auto-prompting
                        // until user manually retries or app is re-locked
                        if !manual {
                            self?.allowAutoAuthentication = false
                        }
                    }
                }
            }
        } else {
            // No biometrics available, just unlock (or handle passcode fallback if desired)
            isLocked = false
        }
    }
    
    func lock() {
        if isBiometricEnabled {
            // If we are currently currently authenticating, don't reset state/timer.
            // This happens when FaceID prompt appears (app becomes inactive).
            if isAuthenticating { return }
            
            isLocked = true
            isAuthenticating = false
            // Reset auto-authentication permission when locking (e.g. entering background)
            allowAutoAuthentication = true
            backgroundEntryTime = Date()
        }
    }
}
