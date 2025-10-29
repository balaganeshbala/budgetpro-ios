//
//  DatePickerDialog.swift
//  BudgetPro
//
//  Created by Balaganesh S on 10/10/25.
//

import SwiftUI

// MARK: - Date Picker Dialog

struct DatePickerDialog: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.overlayBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Select Date")
                    .font(.appFont(_: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 180)
                
                HStack(spacing: 20) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.appFont(_: 16, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .modify {
                        if #available(iOS 26.0, *) {
                            $0.liquidGlassProminent()
                        } else {
                            $0.buttonStyle(.borderedProminent)
                        }
                    }
                    .tint(Color.secondarySystemFill)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.appFont(_: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .modify {
                        if #available(iOS 26.0, *) {
                            $0.liquidGlassProminent()
                        } else {
                            $0.buttonStyle(.borderedProminent)
                        }
                    }
                    .tint(Color.primary)
                }
            }
            .padding(24)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

#Preview("DatePickerDialog") {
    
    @State var isPresented: Bool = true
    @State var selectedDate: Date = Date()
    
    DatePickerDialog(selectedDate: $selectedDate, isPresented: $isPresented)
}
