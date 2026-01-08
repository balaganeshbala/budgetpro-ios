//
//  ModernSummaryItem.swift
//  BudgetPro
//
//  Created by Balaganesh on 08/01/26.
//

import SwiftUI

struct ModernSummaryItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            RowItemIcon(categoryIcon: icon, iconShape: .circle)
        
            Text(title)
                .font(.appFont(14, weight: .regular))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.appFont(16, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
