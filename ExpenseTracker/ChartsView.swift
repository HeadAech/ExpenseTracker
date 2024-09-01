//
//  ChartsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI
import Charts
import SwiftData

struct LastAndCurrentMonthExpensesChart: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: Expense.currentMonthPredicate()) private var currentMonthExpenses: [Expense]
    
    @Query(filter: Expense.lastMonthPredicate()) private var lastMonthExpenses: [Expense]
    
    // Calculate the sum of today's expenses
    private var currentMonthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.value }
    }
    
    // Calculate the sum of today's expenses
    private var lastMonthTotal: Double {
        lastMonthExpenses.reduce(0) { $0 + $1.value }
    }
    
    private var areNotZero: Bool {
        return lastMonthTotal != 0 || currentMonthTotal != 0
    }
    
//    private var currentMonthTotal: Double = 25.99
//    private var lastMonthTotal: Double = 13.50
    
    let currentMonthName: String
    let lastMonthName: String
    
    init() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL" // Full month name (e.g., January, February)
        
        // Get the current month
        let now = Date()
        currentMonthName = dateFormatter.string(from: now)
        
        // Calculate the start of the previous month
        var previousMonthComponents = calendar.dateComponents([.year, .month], from: now)
        previousMonthComponents.month = (previousMonthComponents.month ?? 0) - 1
        
        // Get the previous month's date
        let previousMonthDate = calendar.date(from: previousMonthComponents) ?? Date()
        lastMonthName = dateFormatter.string(from: previousMonthDate)
    }
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var isShowingChart: Bool = false
    
    var body: some View {
        VStack{
            if isShowingChart {
                
                Chart{
                    BarMark(x: .value("Last Month", lastMonthName), y: .value("Total", lastMonthTotal))
                        .cornerRadius(3)
                        .foregroundStyle(.opacity(0.7))
                    
                    BarMark(x: .value("This Month", currentMonthName), y: .value("Total", currentMonthTotal))
                        .cornerRadius(3)
                    //                    .annotation(position: .overlay) {
                    //                        Text(currentMonthTotal, format: .currency(code: "PLN")).bold().font(.caption)
                    //                            .rotationEffect(.degrees(-90))
                    //                    }
                }
                .foregroundStyle(Colors().getColor(for: gradientColorIndex).gradient)
                .animation(.easeInOut, value: lastMonthTotal)
                .animation(.easeInOut, value: currentMonthTotal)
                .transition(.scale)
                
            } else {
                
                VStack{
                    Spacer()
                    Text("Brak danych")
                        .font(.headline)
                    Spacer()
                }
                
                
            }
        }
        .onAppear {
            animateShowingChart()
        }
        .onChange(of: areNotZero) { oldValue, newValue in
            animateShowingChart()
        }

    }
    
    private func animateShowingChart() {
        if currentMonthTotal != 0 || lastMonthTotal != 0 {
            withAnimation{
                isShowingChart = true
            }
        } else {
            withAnimation{
                isShowingChart = false
            }
        }
    }
}

struct BudgetUsageView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: Expense.currentMonthPredicate()) private var currentMonthExpenses: [Expense]
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    // Calculate the sum of today's expenses
    private var currentMonthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.value }
    }
    
    @AppStorage("settings:monthlyBudget") private var monthlyBudget: Double = 100.0
    
    private var remainingBudget: Double {
        let r = monthlyBudget - currentMonthTotal
        if r < 0 {
            return 0
        }
        return r
    }
    
    private var a: Double = 80.0
    private var b: Double = 20.0
    
    var body: some View {
        Chart{
            SectorMark(angle: .value("Pozostało", remainingBudget), angularInset: 1.0)
            SectorMark(angle: .value("Ten miesiąc", currentMonthTotal), angularInset: 1.0)
                .foregroundStyle(.opacity(0.7))
        }
        .foregroundStyle(Colors().getColor(for: gradientColorIndex).gradient)
        .animation(.easeInOut, value: remainingBudget)
        .animation(.easeInOut, value: currentMonthTotal)
    }
}

#Preview {
    LastAndCurrentMonthExpensesChart()
}
