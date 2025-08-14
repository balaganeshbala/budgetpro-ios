//
//  Helper.swift
//  BudgetPro
//
//  Created by Balaganesh Balaganesh on 14/08/25.
//


func monthYearTitle(month: Int, year: Int) -> String {
    let monthNames: [String] = [
        "", "January", "February", "March",
        "April", "May", "June", "July",
        "August", "September", "October",
        "November", "December"
    ]
    return "\(monthNames[month]) \(year)"
}
