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
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var value: Double
    var image: Data?
    
    init(name: String, date: Date, value: Double) {
        self.name = name
        self.date = date
        self.value = value
    }
    
    init() {
        self.name = ""
        self.date = .now
        self.value = 0
        self.mock()
    }
    
    func mock() {
        self.name = "Mock Expense"
        // Generate a random number of days between -7 and 7
        let randomDays = Int.random(in: -7...7)
        
        // Add the random number of days to the current date
        if let randomDate = Calendar.current.date(byAdding: .day, value: randomDays, to: .now) {
            self.date = randomDate
        } else {
            self.date = .now // Fallback to current date in case of failure
        }
        
        self.value = Double.random(in: 50...350)
    }
    
    func addToDate(days: Int) {
        if let randomDate = Calendar.current.date(byAdding: .day, value: days, to: .now) {
            self.date = randomDate
        } else {
            self.date = .now // Fallback to current date in case of failure
        }
    }
    
    // Function to summarize expenses by date
    func summarizeExpenses(expenses: [Expense]) -> [(date: Date, totalValue: Double)] {
        // Create a dictionary to hold the summed values by date
        var expenseDict = [Date: Double]()
        
        let calendar = Calendar.current
        
        // Iterate over expenses
        for expense in expenses {
            // Get the start of the day for the date (ignoring the time component)
            let startOfDay = calendar.startOfDay(for: expense.date)
            
            // Sum the values for the same date
            if let currentTotal = expenseDict[startOfDay] {
                expenseDict[startOfDay] = currentTotal + expense.value
            } else {
                expenseDict[startOfDay] = expense.value
            }
        }
        
        // Convert the dictionary to an array of tuples
        let summarizedExpenses = expenseDict.map { (date, totalValue) in
            (date: date, totalValue: totalValue)
        }
        
        // Sort the array by date
        return summarizedExpenses.sorted { $0.date < $1.date }
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
            let now = Date()
            
            // Get the start of the current month (00:00:00)
            let startOfMonthComponents = calendar.dateComponents([.year, .month], from: now)
            guard let startOfMonth = calendar.date(from: startOfMonthComponents) else {
                fatalError("Failed to calculate start of the month")
            }
            
            // Get the end of the current month (23:59:59)
            let endOfMonthComponents = DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59)
            guard let endOfMonth = calendar.date(byAdding: endOfMonthComponents, to: startOfMonth) else {
                fatalError("Failed to calculate end of the month")
            }
            
            return #Predicate<Expense> { expense in
                expense.date >= startOfMonth && expense.date <= endOfMonth
            }
    }
    
    static func lastMonthPredicate() -> Predicate<Expense> {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the previous month (00:00:00)
        var startOfMonthComponents = calendar.dateComponents([.year, .month], from: now)
        startOfMonthComponents.month = (startOfMonthComponents.month ?? 0) - 1
        guard let startOfPreviousMonth = calendar.date(from: startOfMonthComponents) else {
            fatalError("Failed to calculate start of the previous month")
        }
        
        // Get the end of the previous month (23:59:59)
        let endOfPreviousMonthComponents = DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59)
        guard let endOfPreviousMonth = calendar.date(byAdding: endOfPreviousMonthComponents, to: startOfPreviousMonth) else {
            fatalError("Failed to calculate end of the previous month")
        }
        
        return #Predicate<Expense> { expense in
            expense.date >= startOfPreviousMonth && expense.date <= endOfPreviousMonth
        }
    }
    
    static func lastWeekPredicate() -> Predicate<Expense> {
        let calendar = Calendar.current

        let today = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        
        let sevenDaysBack = calendar.date(byAdding: .day, value: -8, to: today) ?? .now

        return #Predicate<Expense> { expense in
            expense.date >= sevenDaysBack && expense.date <= today
        }
    }
    
    static func expensesBetweenPredicate(from startDate: Date, to endDate: Date) -> Predicate<Expense> {
        return #Predicate<Expense> { expense in
            expense.date >= startDate && expense.date <= endDate
        }
    }
}
