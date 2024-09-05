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
                    BarMark(x: .value("LAST_MONTH_STRING", lastMonthName), y: .value("TOTAL_STRING", lastMonthTotal))
                        .cornerRadius(3)
                        .foregroundStyle(.opacity(0.7))
                    
                    BarMark(x: .value("THIS_MONTH_STRING", currentMonthName), y: .value("TOTAL_STRING", currentMonthTotal))
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
                    Text("NO_DATA_STRING")
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
            SectorMark(angle: .value("REMAINING_STRING", remainingBudget), angularInset: 1.0)
            SectorMark(angle: .value("THIS_MONTH_STRING", currentMonthTotal), angularInset: 1.0)
                .foregroundStyle(.opacity(0.7))
        }
        .foregroundStyle(Colors().getColor(for: gradientColorIndex).gradient)
        .animation(.easeInOut, value: remainingBudget)
        .animation(.easeInOut, value: currentMonthTotal)
    }
}

struct LastWeekExpensesChart: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: Expense.lastWeekPredicate()) private var lastWeekExpenses: [Expense]
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var currentActiveExpense: Expense?
    
    @State private var expenses: [Expense] = []
    
    @State private var showingNoDataView: Bool = false
    
    private var lastSevenDays: [Date] {
        var arr : [Date] = []
        
        let calendar = Calendar.current
        
        let today = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? calendar.startOfDay(for: .now)
        
        for i in 1...7 {
            arr.append(calendar.date(byAdding: .day, value: -i, to: today) ?? .now)
        }
        
        return arr
    }
    
//    private var testExpenses: [Expense] {
//        var arr: [Expense] = []
//        for i in 1...7{
//            var e: Expense = Expense()
//            e.addToDate(days: -i)
//            arr.append(e)
//        }
//        return arr
//    }
//    
    private var expenseAvg: Double {
        guard !expenses.isEmpty else {
            return 0.0 // Return 0 if the list is empty to avoid division by zero
        }
        
        let totalValue = lastWeekExpenses.reduce(0.0) { (result, expense) -> Double in
            return result + expense.value
        }
        
        return totalValue / Double(lastWeekExpenses.count)
    }
    
    var body: some View {
        
        let max = expenses.max { item1, item2 in
            return item2.value > item1.value
        }?.value ?? 0
        
        Chart{
            if expenseAvg > 0{
                RuleMark(y: .value("AVERAGE_STRING", expenseAvg))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                //                    .annotation(alignment: .leading) {
                //                        Text("Średnia")
                //                    }
            }
            ForEach(Array(expenses.enumerated()), id: \.element){ index, expense in
                BarMark(x: .value("DAY_STRING", lastSevenDays[index], unit: .day),
                        y: .value("PAID_STRING", expense.value)
                )
                .foregroundStyle(Colors().getColor(for: gradientColorIndex).opacity(0.85).gradient)
                
                if let currentActiveExpense,currentActiveExpense.id == expense.id {
                    
                    RuleMark(x: .value("DAY_STRING", expense.date, unit: .day))
                        .annotation(position: .top) {
                            GroupBox{
                                HStack{
                                    Text("TOTAL_STRING")
                                        .font(.headline)
                                    Spacer()
                                }
                                HStack{
                                    Text(currentActiveExpense.value, format: .currency(code: "PLN"))
                                        .font(.callout)
                                    Spacer()
                                }
                                HStack{
                                    Text(currentActiveExpense.date.formatted(.dateTime.month().day().year()))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        
                }
            }
            
        }
        .chartXAxis {
            AxisMarks(values: expenses.map {$0.date }) {date in
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .opacity(showingNoDataView ? 0 : 1)
        .overlay{
            if showingNoDataView {
                ContentUnavailableView(label: {
                    Label("NO_DATA_STRING", systemImage: "chart.bar.xaxis")
                }, description: {
                    Text("ADD_EXPENSES_STATISTICS_DESCRIPTION")
                }).animation(.easeInOut, value: showingNoDataView)
            }
        }
        .chartYScale(domain: 0...(max + 2))
        //        On drag show more details
        .chartOverlay(content: { ChartProxy in
            GeometryReader{innerProxy in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged{ value in
                                //            get location of the drag
                                let location = value.location
                                
                                //             extract date from the location
                                if let date: Date = ChartProxy.value(atX: location.x){
                                    
                                    let calendar = Calendar.current
                                    let day = calendar.component(.day, from: date)
                                    
                                    //     assign an object from that location
                                    if let currentExpense = expenses.first(where: {expense in
                                        calendar.component(.day, from: expense.date) == day
                                    }) {
                                        withAnimation(.bouncy){
                                            self.currentActiveExpense = currentExpense
                                        }
                                    }
                                }
                            }
                            .onEnded({ value in
                                withAnimation(.bouncy){
                                    self.currentActiveExpense = nil
                                }
                            })
                    )
            }
        })
        .animation(.bouncy(duration: 0.8), value: expenses)
        .onAppear{
            update()
        }
        .onChange(of: lastWeekExpenses) { oldValue, newValue in
            update()
        }
        
        if !showingNoDataView{
            HStack{
                Image(systemName: "line.diagonal")
                    .rotationEffect(.degrees(45))
                    .foregroundStyle(Colors().getColor(for: gradientColorIndex))
                
                Text("AVERAGE_EXPENSES_STRING")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
    }
    
    
    func summarizeExpenses() -> [Expense] {
        let summed = Expense().summarizeExpenses(expenses: lastWeekExpenses)
        var arr : [Expense] = []
        for date in lastSevenDays {
            let e: Expense = Expense()
            e.date = date
            e.value = 0
            arr.append(e)
        }
        
        var i = 0
        
        for (key, value) in summed {
            for expense in arr {
                if key == expense.date {
                    expense.value = value
                }
            }
            
            i += 1
        }
        return arr
    }
    
    func update() {
        expenses = summarizeExpenses()
        
        if lastWeekExpenses.isEmpty {
            withAnimation{
                showingNoDataView = true
            }
        } else {
            withAnimation {
                showingNoDataView = false
            }
        }
    }
}

struct DateRangeExpensesChart: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var dateRangeExpenses: [Expense]
    
    init(predicate: Predicate<Expense>) {
        // Initialize the @Query with a default predicate
        _dateRangeExpenses = Query(filter: predicate)
        expenses = summarizeExpenses()
    }
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var currentActiveExpense: Expense?
    
//    private var testExpenses: [Expense] {
//        var arr: [Expense] = []
//        for i in 1...7{
//            var e: Expense = Expense()
//            e.addToDate(days: -i)
//            arr.append(e)
//        }
//        return arr
//    }
    
    @State private var expenses: [Expense] = []
    
    @State private var showingNoDataView: Bool = false
    
    var body: some View {
        
        let gradient = LinearGradient(
            gradient: Gradient (
                colors: [
                    Colors().getColor(for: gradientColorIndex).opacity(0.5),
                    Colors().getColor(for: gradientColorIndex).opacity(0.2),
                    Colors().getColor(for: gradientColorIndex).opacity(0.05),
                ]
            ),
            startPoint: .top,
            endPoint: .bottom)
        
        let max = expenses.max { item1, item2 in
            return item2.value > item1.value
        }?.value ?? 0
        
        
        Chart {
            ForEach(expenses, id: \.self){ expense in
                LineMark(x: .value("DAY_STRING", expense.date, unit: .day),
                         y: .value("PAID_STRING", expense.value)
                )
                .foregroundStyle(Colors().getColor(for: gradientColorIndex).opacity(0.85).gradient)
                .interpolationMethod(.catmullRom)
                .shadow(radius: 5)
                .symbol{
                    Circle()
                        .fill(Colors().getColor(for: gradientColorIndex).gradient)
                        .frame(width: 10, height: 10)
                }
                
                
                
                
                AreaMark(x: .value("DAY_STRING", expense.date, unit: .day),
                         y: .value("PAID_STRING", expense.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(gradient)
                
                if let currentActiveExpense,currentActiveExpense.id == expense.id {
                    
                    RuleMark(x: .value("DAY_STRING", expense.date, unit: .day))
                        .annotation(position: .top) {
                            GroupBox{
                                HStack{
                                    Text("TOTAL_STRING")
                                        .font(.headline)
                                    Spacer()
                                }
                                HStack{
                                    Text(currentActiveExpense.value, format: .currency(code: "PLN"))
                                        .font(.callout)
                                    Spacer()
                                }
                                HStack{
                                    Text(currentActiveExpense.date.formatted(.dateTime.month().day().year()))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        
                }
            }
            
        }
        .opacity(showingNoDataView ? 0 : 1)
        .overlay{
            if showingNoDataView {
                ContentUnavailableView(label: {
                    Label("NO_DATA_STRING", systemImage: "chart.xyaxis.line")
                }, description: {
                    Text("ADD_EXPENSES_STATISTICS_DESCRIPTION")
                }).animation(.easeInOut, value: showingNoDataView)
            }
        }
        .chartYScale(domain: 0...(max + 2))
        //        On drag show more details
        .chartOverlay(content: { ChartProxy in
            GeometryReader{innerProxy in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged{ value in
                                //            get location of the drag
                                let location = value.location
                                
                                //             extract date from the location
                                if let date: Date = ChartProxy.value(atX: location.x){
                                    
                                    let calendar = Calendar.current
                                    let day = calendar.component(.day, from: date)
                                    
                                    //     assign an object from that location
                                    if let currentExpense = expenses.first(where: {expense in
                                        calendar.component(.day, from: expense.date) == day
                                    }) {
                                        withAnimation{
                                            self.currentActiveExpense = currentExpense
                                        }
                                    }
                                }
                            }
                            .onEnded({ value in
                                withAnimation{
                                    self.currentActiveExpense = nil
                                }
                            })
                    )
            }
        })
        .animation(.smooth(duration: 0.8), value: expenses)
        .onAppear{
            update()
        }
        .onChange(of: dateRangeExpenses) { oldValue, newValue in
            update()
        }
        
        
    }
    
    func summarizeExpenses() -> [Expense] {
        let summed = Expense().summarizeExpenses(expenses: dateRangeExpenses)
        var arr : [Expense] = []
        for (key, value) in summed {
            let e: Expense = Expense()
            e.date = key
            e.value = value
            arr.append(e)
        }
        return arr
    }
    
    func update() {
        expenses = summarizeExpenses()
        
        if expenses.isEmpty {
            withAnimation{
                showingNoDataView = true
            }
        } else {
            withAnimation {
                showingNoDataView = false
            }
        }
    }
}

