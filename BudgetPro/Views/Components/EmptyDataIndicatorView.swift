//
//  EmptyDataIndicatorView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/01/26.
//

import SwiftUI

struct EmptyDataIndicatorView: View {
    let icon: String
    let title: String
    let bodyText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            
            Text(title)
                .font(.appFont(14, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(bodyText)
                .font(.appFont(14))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.all, 16)
    }
}