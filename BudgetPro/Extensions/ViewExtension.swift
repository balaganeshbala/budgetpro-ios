//
//  ViewExtension.swift
//  BudgetPro
//
//  Created by Balaganesh S on 20/09/25.
//

import SwiftUI

extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
    
    @available(iOS 26.0, *)
    func liquidGlass() -> some View {
        modifier(LiquidGlassStyle())
    }
    
    @available(iOS 26.0, *)
    func liquidGlassProminent() -> some View {
        modifier(LiquidGlassStyle(prominent: true))
    }
}

@available(iOS 26.0, *)
struct LiquidGlassStyle: ViewModifier {
    
    let prominent: Bool
    
    init(prominent: Bool = false) {
        self.prominent = prominent
    }
    
    func body(content: Content) -> some View {
        if self.prominent {
            content
                .buttonStyle(.glassProminent)
        } else {
            content
                .buttonStyle(.glass)
        }
    }
}
