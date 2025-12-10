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
    let tool_calls: [ToolCall]?
}

struct ToolCall: Codable {
    let id: String
    let function: FunctionCall
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String // JSON string
}

// MARK: - Service Implementation
class RealAIService: AIService {
    
    private let tool: FinancialDataTool
    private let userId: String
    private let supabaseUrl: String
    private let supabaseKey: String // Anon Key
    
    // Conversation History
    private var history: [[String: Any]] = []
    
    init(tool: FinancialDataTool, userId: String) {
        self.tool = tool
        self.userId = userId
        
        // In a real app, fetch these from Info.plist or Config
        // Ideally we shouldn't hardcode them, but for this implementation we'll assume they are available via Bundle or Config.
        // For now, I'll use placeholders that the user must replace or inject.
        self.supabaseUrl = "https://YOUR_PROJECT_REF.supabase.co/functions/v1/budget-assistant"
        self.supabaseKey = "YOUR_ANON_KEY"
    }
    
    // Injectable initializer for ease of use if config is external
    init(tool: FinancialDataTool, userId: String, url: String, key: String) {
        self.tool = tool
        self.userId = userId
        self.supabaseUrl = url
        self.supabaseKey = key
    }
    
    func sendMessage(_ text: String) async throws -> AIResponse {
        // 1. Append User Message to History
        history.append(["role": "user", "content": text])
        
        // 2. Call Edge Function (Round 1)
        let response1 = try await callEdgeFunction(messages: history)
        
        guard let message = response1.choices.first?.message else {
            return AIResponse(text: "Sorry, I didn't get a response from the server.", isError: true)
        }
        
        // 3. Handle Tool Calls
        if let toolCalls = message.tool_calls, !toolCalls.isEmpty {
            // Append Assistant Message with Tool Calls to History
            // We need to match the format expected by OpenAI API (even if proxied)
            // Ideally the Edge Function handles history, but if we send full history from client, we mimic the structure.
            // Simplified: We assume the backend is stateless for this request or we send what we have.
            
            // For this implementation, let's treat history as local state we send up.
            // Note: Swift Dictionary<String, Any> is tricky with JSONSerialization if not careful.
            
            // Let's Execute Tools
            for toolCall in toolCalls {
                 let result = await executeTool(call: toolCall)
                 
                 // Append Tool Result to History
                 // Note: We need to append the ASSISTANT's tool_calls message first, then the TOOL result.
                 // This complexity is handled better if we strictly model the messages.
            }
            
            // For simplicity in this demo, we will:
            // 1. Send the tool result back in a new message context (mimicking the flow).
            // WARNING: Proper OpenAI "Tool use" requires sending the PREVIOUS assistant message + the TOOL output.
            
            // Refined Approach:
            // We will do a recursive call or simply a second request.
            // Let's assume the Edge Function creates a 'run' effectively.
            
            // Since we are managing history on Client:
            // We must add the assistant message that requested the tool.
            
            // Since `EdgeMessage` is Codable, let's convert it to Dictionary for history storage
            // (Skipping deep JSON conversion for brevity in this snippet, using simplified flow)
            
            // 3b. Execute Tool
            let toolCall = toolCalls[0] // Simplify to handle first tool call for now
            let resultString = await executeTool(call: toolCall)
            
            // 3c. Update History for Round 2
            // We need to send:
            // - User: "Spend on food?"
            // - Assistant: (Tool Call)
            // - Tool: "4500"
            
            // Awaiting second response...
            // To make this robust without huge boilerplate, we'll send a structured "Follow Up"
            // For now, let's assume the Edge Function is stateless request-response.
            // We send [User, Assistant(ToolCall), ToolResult]
            
            var round2Messages = history
            
            // Add Assistant Message (Simplified representation)
            round2Messages.append([
                "role": "assistant",
                "content": message.content ?? "",
                "tool_calls": [
                    [
                        "id": toolCall.id,
                        "type": "function",
                        "function": [
                            "name": toolCall.function.name,
                            "arguments": toolCall.function.arguments
                        ]
                    ]
                ]
            ])
            
            // Add Tool Message
            round2Messages.append([
                "role": "tool",
                "tool_call_id": toolCall.id,
                "name": toolCall.function.name,
                "content": resultString // Result from our local DB
            ])
            
            // 4. Call Edge Function (Round 2)
            let response2 = try await callEdgeFunction(messages: round2Messages)
            
            if let finalContent = response2.choices.first?.message.content {
                // Update local history with final answer
                history = round2Messages
                history.append(["role": "assistant", "content": finalContent])
                return AIResponse(text: finalContent, isError: false)
            }
        }
        
        // No tool call, just text
        if let content = message.content {
            history.append(["role": "assistant", "content": content])
            return AIResponse(text: content, isError: false)
        }
        
        return AIResponse(text: "I confused myself.", isError: true)
    }
    
    // MARK: - Helpers
    
    private func executeTool(call: ToolCall) async -> String {
        let name = call.function.name
        guard let data = call.function.arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Error parsing arguments"
        }
        
        switch name {
        case "get_expenses_total":
            let category = args["category"] as? String
            let month = args["month"] as? Int
            let year = args["year"] as? Int
            let total = await tool.getExpensesTotal(category: category, month: month, year: year)
            return "\(total)"
            
        case "get_income_total":
            let category = args["category"] as? String
            let month = args["month"] as? Int
            let year = args["year"] as? Int
            let total = await tool.getIncomeTotal(category: category, month: month, year: year)
            return "\(total)"
            
        case "get_financial_goals":
            return await tool.getFinancialGoals()
            
        case "get_budget_details":
            let month = args["month"] as? Int ?? Calendar.current.component(.month, from: Date())
            let year = args["year"] as? Int ?? Calendar.current.component(.year, from: Date())
            return await tool.getBudgetCategories(month: month, year: year)
            
        default:
            return "Unknown tool"
        }
    }
    
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
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Print error body for debugging
            if let str = String(data: data, encoding: .utf8) {
                print("Server Error: \(str)")
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(EdgeFunctionResponse.self, from: data)
    }
}
