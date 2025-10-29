//
//  AppProgressView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 29/10/25.
//

import SwiftUI

struct ScreenProgressView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
    }
}

struct ButtonProgressView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
    }
}

struct LoadingOverlay: View {
    let titleText: String
    
    var body: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                        .scaleEffect(1.5)
                    
                    Text(titleText)
                        .font(.appFont(16, weight: .medium))
                        .foregroundColor(.primaryText)
                        .padding(.top, 16)
                }
                .padding(32)
                .background(Color.appBackground.opacity(0.8))
                .cornerRadius(16)
            )
    }
}

struct LoadingView: View {
    let titleText: String
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                .scaleEffect(1.5)
            
            Text(titleText)
                .font(.appFont(16, weight: .medium))
                .foregroundColor(.secondaryText)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
