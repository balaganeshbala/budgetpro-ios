//
//  CategoryProtocol.swift
//  BudgetPro
//
//  Created by Claude on 14/08/25.
//

import SwiftUI

// MARK: - Category Protocol
protocol CategoryProtocol: Hashable, CaseIterable {
    var displayName: String { get }
    var iconName: String { get }
    var color: Color { get }
}