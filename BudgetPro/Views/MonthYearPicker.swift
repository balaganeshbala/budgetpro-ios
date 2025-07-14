//
//  MonthYearPicker.swift
//  BudgetPro
//
//  Created by Balaganesh S on 14/07/25.
//


import SwiftUI

struct MonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let onChanged: (Int, Int) -> Void
    
    @State private var showingPicker = false
    
    private let months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1))
    }()
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                
                Text("\(months[selectedMonth - 1]) \(String(selectedYear))")
                    .font(.sora(16, weight: .semibold))
                    .foregroundColor(.black)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .sheet(isPresented: $showingPicker) {
            MonthYearPickerSheet(
                selectedMonth: $selectedMonth,
                selectedYear: $selectedYear,
                months: months,
                years: years,
                onChanged: onChanged
            )
        }
    }
}

struct MonthYearPickerSheet: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Environment(\.presentationMode) var presentationMode
    
    let months: [String]
    let years: [Int]
    let onChanged: (Int, Int) -> Void
    
    @State private var tempMonth: Int
    @State private var tempYear: Int
    
    init(selectedMonth: Binding<Int>, selectedYear: Binding<Int>, months: [String], years: [Int], onChanged: @escaping (Int, Int) -> Void) {
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
        self.months = months
        self.years = years
        self.onChanged = onChanged
        self._tempMonth = State(initialValue: selectedMonth.wrappedValue)
        self._tempYear = State(initialValue: selectedYear.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.sora(16))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    
                    Spacer()
                    
                    Text("Select Month & Year")
                        .font(.sora(18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button("Done") {
                        selectedMonth = tempMonth
                        selectedYear = tempYear
                        onChanged(tempMonth, tempYear)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.sora(16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Picker
                HStack(spacing: 0) {
                    // Month Picker
                    Picker("Month", selection: $tempMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(months[month - 1])
                                .font(.sora(16))
                                .tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    
                    // Year Picker
                    Picker("Year", selection: $tempYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .font(.sora(16))
                                .tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct MonthYearPicker_Previews: PreviewProvider {
    static var previews: some View {
        MonthYearPicker(
            selectedMonth: .constant(7),
            selectedYear: .constant(2025),
            onChanged: { _, _ in }
        )
    }
}
