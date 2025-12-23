//
//  RealAIService.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import Foundation

// MARK: - API Response Models
struct EdgeFunctionResponse: Codable {
    let id: String?
    let choices: [Choice]
}

struct Choice: Codable {
    let message: EdgeMessage
}

struct EdgeMessage: Codable {
    let role: String
    let content: String?
    // Tool calls are no longer needed on the client for Text-to-SQL
}

// MARK: - Service Implementation
class RealAIService: AIService {
    
    private let tool: FinancialDataTool // Kept ref for now if needed, but unused in SQL flow
    private let userId: String
    private let supabaseUrl: String
    private let supabaseKey: String // Anon Key
    
    // Conversation History
    private var history: [[String: Any]] = []
    
    init(tool: FinancialDataTool, userId: String) {
        self.tool = tool
        self.userId = userId
        
        // Load from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let urlString = config["SupabaseBudgetAssistantURL"] as? String,
              let anonKey = config["SupabaseAnonKey"] as? String else {
            fatalError("Could not load Supabase configuration from Config.plist")
        }
        
        self.supabaseUrl = urlString
        self.supabaseKey = anonKey
    }
    
    func sendMessage(_ text: String) async throws -> AIResponse {
        // 1. Append User Message to History
        history.append(["role": "user", "content": text])
        
        // 2. Call Edge Function
        // The Edge Function now handles SQL generation, execution, and summarization internally.
        // We just expect a final text response.
        let response = try await callEdgeFunction(messages: history)
        
        guard let message = response.choices.first?.message, let content = message.content else {
            return AIResponse(text: "Sorry, I didn't get a valid response from the server.", isError: true)
        }
        
        // 3. Update History & Return
        history.append(["role": "assistant", "content": content])
        return AIResponse(text: content, isError: false)
    }
    
    // MARK: - Helpers
    
    private func callEdgeFunction(messages: [[String: Any]]) async throws -> EdgeFunctionResponse {
        guard let url = URL(string: supabaseUrl) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "messages": messages,
            "user_id": userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle Errors
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let str = String(data: data, encoding: .utf8) {
                print("Server Error: \(str)")
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(EdgeFunctionResponse.self, from: data)
    }
}
