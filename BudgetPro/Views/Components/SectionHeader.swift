//
//  SectionHeader.swift
//  BudgetPro
//
//  Created by Balaganesh S on 08/01/26.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.appFont(18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.appFont(14, weight: .regular))
                    .foregroundColor(.secondaryText)
            }
        }
    }
}