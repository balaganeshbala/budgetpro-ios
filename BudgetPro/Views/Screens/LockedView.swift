//
//  LockedView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/01/26.
//

import SwiftUI

struct LockedView: View {
    @StateObject var viewModel: AppLockViewModel
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondaryText)
                
                Text("Budget Pro - Locked")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.secondaryText)
                
                Button {
                    viewModel.manualAuthenticate()
                } label: {
                    Text("Unlock")
                        .font(.appFont(16, weight: .semibold))
                        .frame(width: 100, height: 40)
                }
                .tint(Color.primary)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    LockedView(viewModel: AppLockViewModel())
        .preferredColorScheme(.dark)
    
}
