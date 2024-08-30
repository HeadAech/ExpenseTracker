//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import Foundation
import SwiftData

@Model
class Expense {
    var name: String
    var date: Date
    var value: Double
    var image: Data?
    
    init(name: String, date: Date, value: Double) {
        self.name = name
        self.date = date
        self.value = value
    }
}

extension Expense {
    
    static func currentPredicate() -> Predicate<Expense> {
        let currentDate = Date.now
        
        return #Predicate<Expense> { expense in
            expense.date > currentDate
        }
    }
    
    static func pastPredicate() -> Predicate<Expense> {
        let currentDate = Date.now
        
        return #Predicate<Expense> { expense in
            expense.date < currentDate
        }
    }
    
    static func todayPredicate() -> Predicate<Expense> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date.now) // Start of today
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)! // Start of tomorrow
        
        return #Predicate<Expense> { expense in
            expense.date >= startOfDay && expense.date < endOfDay
        }
    }
    
    static func currentMonthPredicate() -> Predicate<Expense> {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date.now))! // Start of the current month
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)! // End of the current month
        
        return #Predicate<Expense> { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
    }
}
