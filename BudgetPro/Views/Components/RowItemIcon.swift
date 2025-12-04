//
//  RowItemIcon.swift
//  BudgetPro
//
//  Created by Balaganesh Balaganesh on 04/12/25.
//

import SwiftUI

enum IconShape {
    case circle
    case roundedRectangle
}

struct RowItemIcon: View {
    let categoryIcon: String
    let iconShape: IconShape
    let iconColor: Color?
    let backgroundColor: Color?
    
    init(categoryIcon: String, iconShape: IconShape, iconColor: Color? = nil, backgroundColor: Color? = nil) {
        self.categoryIcon = categoryIcon
        self.iconShape = iconShape
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Group {
            switch iconShape {
            case .circle:
                Circle()
                    .fill(
                        backgroundColor ?? (iconColor ?? Color.primary).opacity(0.1)
                    )
                    .frame(width: 40, height: 40)
            case .roundedRectangle:
                RoundedRectangle(cornerRadius: 10, style: .circular)
                    .fill(
                        backgroundColor ?? (iconColor ?? Color.primary).opacity(0.1)
                    )
                    .frame(width: 40, height: 40)
            }
        }
        .overlay(
            Image(systemName: categoryIcon)
                .foregroundStyle(
                    iconColor ?? Color.secondary
                )
                .font(.system(size: 16, weight: .bold))
        )
    }
}
