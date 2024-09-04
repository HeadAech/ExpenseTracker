//
//  StatisticsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI
import SwiftData

enum StatisticsViewType {
    case last7DaysExpenses
    case dateRangeExpenses
    
    var id: Self { self }
}

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses : [Expense]
    
    @State private var chosenStatsView: StatisticsViewType = .last7DaysExpenses
    
    @State private var dateFrom: Date = Calendar.current.date(byAdding: .day, value: -3, to: .now)!

    
    @State private var dateTo: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
    
    @State private var predicate: Predicate<Expense> = .false
    
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var midnight: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1 // The last second of the day
        return Calendar.current.date(byAdding: components, to: today) ?? today
    }
    
    
    var body: some View {
        
        VStack{
            HStack{
                Text("Statystyki")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Picker("Widok", selection: $chosenStatsView.animation()) {
                    Text("Ostatnie 7 dni").tag(StatisticsViewType.last7DaysExpenses)
                    Text("Zakres dat").tag(StatisticsViewType.dateRangeExpenses)
                }
            }.padding(.horizontal, 0).padding(.vertical, -2)

            if chosenStatsView == .dateRangeExpenses {
                HStack{
                    
                    DatePicker("", selection: $dateFrom, in: ...dateTo, displayedComponents: [.date])
                        .onChange(of: dateFrom) { oldValue, newValue in
                            dateFrom = Calendar.current.startOfDay(for: newValue)
                            predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
                        }.labelsHidden()
                    
                    Image(systemName: "arrow.right")
                    
                    DatePicker("", selection: $dateTo, in: dateFrom...midnight , displayedComponents: [.date])
                        .onChange(of: dateTo) { oldValue, newValue in
                            predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
                        }.labelsHidden()
                    
                }
                .padding(.top, 5)
                .padding(.bottom, 5)
            }
            
            GroupBox{
                
                switch chosenStatsView {
                    case .last7DaysExpenses: LastWeekExpensesChart()
                            .padding(.top, 20)
                            .transition(.blurReplace)
                            .animation(.easeInOut, value: chosenStatsView)
                    case .dateRangeExpenses: DateRangeExpensesChart(predicate: predicate)
                        .transition(.blurReplace)
                        .animation(.easeInOut, value: chosenStatsView)
                }
                
            }
            .frame(height: 300)
            
        }
        .offset(y: -20)
        .padding(.horizontal, 20)
        .onChange(of: expenses) { oldV, newV in
            predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
        }
        .frame(alignment: .top)
        
    }
    
}


struct DateRangeExpensesView: View {
    @Environment(\.modelContext) private var modelContext
 
    @State private var dateFrom: Date = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
    @State private var dateTo: Date = .now

    @Query private var expenses : [Expense]
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var predicate: Predicate<Expense> = .false
    
    var body: some View {
        HStack{
            DatePicker("", selection: $dateFrom, displayedComponents: [.date])
                .onChange(of: dateFrom) { oldValue, newValue in
                    predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
                }
            
            Image(systemName: "arrow.right")
            
            DatePicker("", selection: $dateTo, displayedComponents: [.date])
                .onChange(of: dateTo) { oldValue, newValue in
                    predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
                }
        }
        .onChange(of: expenses) { oldValue, newValue in
            predicate = Expense.expensesBetweenPredicate(from: dateFrom, to: dateTo)
        }
//        Actual chart
        DateRangeExpensesChart(predicate: predicate)
            .padding(.top, 10)
    }

}


#Preview {
    StatisticsView()
}
