//
//  AIService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import Foundation

struct AIResponse {
    let text: String
    let isError: Bool
}

protocol AIService {
    func sendMessage(_ text: String) async throws -> AIResponse
}
