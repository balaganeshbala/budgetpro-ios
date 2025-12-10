//
//  AIChatViewModel.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import Foundation
import Combine

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool // true = user, false = AI
    let timestamp = Date()
}

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    @Published var errorMessage: String?
    
    // In a real app, we'd inject this via Dependency Injection.
    // For now, we'll initialize it here or pass it in.
    private let aiService: AIService
    
    init(aiService: AIService) {
        self.aiService = aiService
        
        // Initial greeting
        messages.append(ChatMessage(text: "Hello! I'm your Budget Assistant. Ask me about your expenses.", isUser: false))
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add User Message
        let userMsg = ChatMessage(text: text, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await aiService.sendMessage(text)
                
                // Add AI Response
                let aiMsg = ChatMessage(text: response.text, isUser: false)
                messages.append(aiMsg)
                
                if response.isError {
                    // Optional: Handle error UI specifically if needed
                }
            } catch {
                errorMessage = "Failed to get response: \(error.localizedDescription)"
                messages.append(ChatMessage(text: "Sorry, I encountered an error connecting to the service.", isUser: false))
            }
            isLoading = false
        }
    }
}
