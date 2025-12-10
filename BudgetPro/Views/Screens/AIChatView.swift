//
//  AIChatView.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Dependency Injection for View
    init(userId: String) {
        // Compose the service graph here (or in a DI container/Coordinator)
        let repo = SupabaseDataFetchRepoService() // Or Mock if we want purely offline
        let tool = FinancialDataTool(repoService: repo, userId: userId)
        // let service = MockAIService(tool: tool)
        
        // REAL AI SERVICE (Connects to Supabase Edge Function)
        // IMPORTANT: Update RealAIService.swift with your actual Supabase URL and Anon Key!
        let service = RealAIService(tool: tool, userId: userId)
        
        _viewModel = StateObject(wrappedValue: AIChatViewModel(aiService: service))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Budget Assistant")
                    .font(.appFont(18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondaryText)
                }
            }
            .padding()
            .background(Color.cardBackground)
            
            Divider()
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(10)
                                    .background(Color.secondarySystemFill)
                                    .cornerRadius(12)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask budget questions...", text: $viewModel.inputText)
                    .font(.appFont(16))
                    .padding(12)
                    .background(Color.secondarySystemFill)
                    .cornerRadius(20)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .background(Color.groupedBackground)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .font(.appFont(16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.appFont(16))
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Text("AI Assistant")
                        .font(.appFont(10))
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                }
                Spacer()
            }
        }
    }
}
