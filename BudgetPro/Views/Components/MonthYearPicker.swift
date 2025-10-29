//
//  MonthYearPicker.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct BorderOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.8), lineWidth: 1)
            )
    }
}

struct MonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let onChanged: (Int, Int) -> Void
    
    @Binding var showingPicker: Bool
    @State private var tempMonth: Int
    @State private var tempYear: Int
    
    private let months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(2023...currentYear)
    }()
    
    init(selectedMonth: Binding<Int>, selectedYear: Binding<Int>, showingPicker: Binding<Bool>, onChanged: @escaping (Int, Int) -> Void) {
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
        self._showingPicker = showingPicker
        self.onChanged = onChanged
        self._tempMonth = State(initialValue: selectedMonth.wrappedValue)
        self._tempYear = State(initialValue: selectedYear.wrappedValue)
    }
    
    var body: some View {
        Button(action: {
            tempMonth = selectedMonth
            tempYear = selectedYear
            showingPicker = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(.primary)
                
                Text("\(months[selectedMonth - 1]) \(String(selectedYear))")
                    .font(.appFont(16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .modify {
            if #available(iOS 26.0, *) {
                $0.liquidGlass()
            } else {
                $0.overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.8), lineWidth: 1)
                )
            }
        }
        .onChange(of: showingPicker) { isShowing in
            if isShowing {
                tempMonth = selectedMonth
                tempYear = selectedYear
            }
        }
    }
    
    func getDialog(tempMonth: Binding<Int>, tempYear: Binding<Int>) -> MonthYearPickerDialog {
        return MonthYearPickerDialog(
            selectedMonth: tempMonth,
            selectedYear: tempYear,
            isPresented: $showingPicker,
            months: months,
            years: years,
            onDone: {
                selectedMonth = tempMonth.wrappedValue
                selectedYear = tempYear.wrappedValue
                onChanged(tempMonth.wrappedValue, tempYear.wrappedValue)
                showingPicker = false
            }
        )
    }
}

struct MonthYearPickerDialog: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    let months: [String]
    let years: [Int]
    let onDone: () -> Void
    
    private var availableMonths: [Int] {
        let currentDate = Date()
        let currentYear = Calendar.current.component(.year, from: currentDate)
        let currentMonth = Calendar.current.component(.month, from: currentDate)
        
        if selectedYear < currentYear {
            // Past year - all months available
            return Array(1...12)
        } else if selectedYear == currentYear {
            // Current year - only past and current months
            return Array(1...currentMonth)
        } else {
            // Future year - no months available
            return []
        }
    }
    
    var body: some View {
        ZStack {
            Color.overlayBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("Select Month & Year")
                    .font(.appFont(_: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 0) {
                    // Month Picker
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(availableMonths, id: \.self) { month in
                            Text(months[month - 1])
                                .font(.appFont(_: 16))
                                .tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .onChange(of: selectedYear) { _ in
                        // Adjust selected month if it's no longer available
                        if !availableMonths.contains(selectedMonth) && !availableMonths.isEmpty {
                            selectedMonth = availableMonths.last ?? 1
                        }
                    }
                    
                    // Year Picker
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .font(.appFont(_: 16))
                                .tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                }
                
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
                    
                    
                    Button(action: onDone) {
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

struct MonthYearPicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode
            VStack {
                MonthYearPicker(
                    selectedMonth: .constant(7),
                    selectedYear: .constant(2025),
                    showingPicker: .constant(false),
                    onChanged: { _, _ in }
                )
                
                // Show dialog preview
                MonthYearPickerDialog(
                    selectedMonth: .constant(7),
                    selectedYear: .constant(2025),
                    isPresented: .constant(true),
                    months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    years: Array(2023...2025),
                    onDone: {}
                )
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            // Dark Mode
            VStack {
                MonthYearPicker(
                    selectedMonth: .constant(7),
                    selectedYear: .constant(2025),
                    showingPicker: .constant(false),
                    onChanged: { _, _ in }
                )
                
                // Show dialog preview
                MonthYearPickerDialog(
                    selectedMonth: .constant(7),
                    selectedYear: .constant(2025),
                    isPresented: .constant(true),
                    months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    years: Array(2023...2025),
                    onDone: {}
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
