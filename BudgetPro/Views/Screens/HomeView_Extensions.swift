//
//  HomeView_Extensions.swift
//  BudgetPro
//
//  Created by Balaganesh S on 09/12/25.
//

import SwiftUI

// MARK: - Extracted UI Components
extension HomeView {
    
    var overlayContent: some View {
        Group {
            // Floating AI Assistant Button
            // Floating AI Assistant Button - REMOVED (Moved to Toolbar)
            
            if showingMonthPicker {
                MonthYearPickerDialog(
                    selectedMonth: $tempMonth,
                    selectedYear: $tempYear,
                    isPresented: $showingMonthPicker,
                    months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    years: Array(2023...Calendar.current.component(.year, from: Date())),
                    onDone: {
                        selectedMonth = tempMonth
                        selectedYear = tempYear
                        Task {
                            await viewModel.loadData(month: tempMonth, year: tempYear)
                        }
                        showingMonthPicker = false
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    var aiChatSheet: some View {
        if #available(iOS 16.0, *) {
            AIChatView(userId: viewModel.userId)
                .presentationDetents([.medium, .large])
        } else {
            AIChatView(userId: viewModel.userId)
        }
    }
}
