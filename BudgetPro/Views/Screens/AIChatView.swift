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
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondaryText : .blue)
                        .padding(10)
                        .background(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondaryText.opacity(0.1) : Color.blue.opacity(0.1))
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
                // Safely convert to AttributedString for Markdown support
                if let attributedString = try? AttributedString(markdown: message.text) {
                    Text(attributedString)
                        .font(.system(size: 16)) // Use system font for reliable Markdown
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                } else {
                    // Fallback if parsing fails
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.text
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if let attributedString = try? AttributedString(markdown: message.text) {
                        Text(attributedString)
                            .font(.system(size: 16)) // Use system font for reliable Markdown
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.cardBackground)
                            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = message.text
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                    } else {
                        Text(message.text)
                            .font(.system(size: 16))
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.cardBackground)
                            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = message.text
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                    }
                    
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
