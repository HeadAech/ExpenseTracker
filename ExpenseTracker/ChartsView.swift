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
                                    Text(currentActiveExpense.value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
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
        print(expenses.count)
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
                                    Text(currentActiveExpense.value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
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

public enum InfluenceExpenseRange: CaseIterable {
    case TODAY
    case LAST_7_DAYS
    case LAST_MONTH
    case LAST_3_MONTHS
    
    var id: Self { self }
    
    var string: LocalizedStringResource {
        switch self {
            
        case .TODAY: "TODAY_STRING"
        case .LAST_7_DAYS: "7_DAYS_STRING"
        case .LAST_MONTH: "MONTH_STRING"
        case .LAST_3_MONTHS: "3_MONTHS_STRING"
            
        }
    }
}

struct InfluenceExpenseChart: View {
    
    @State private var showingNoDataView: Bool = true
    
    @Query private var filteredExpenses: [Expense]
    
    @State private var expenses: [Expense] = []
    
    var expense: Expense
//    var tags: [Tag] = [Tag(name: "Test 1", color: "#ff0000", icon: "tag.fill"), Tag(name: "Test 2", color: "#00ff00", icon: "tag.fill"), Tag(name: "Test 3", color: "#0000ff", icon: "tag.fill")]
    
    
//    private var testExpenses: [Expense]
    
    init(predicate: Predicate<Expense>, expense: Expense) {
        // Initialize the @Query with a default predicate
        _filteredExpenses = Query(filter: predicate)
        self.expense = expense
//        self.testExpenses = []
//        expense.tag = tags[0]
//        testExpenses = populateTest()
        expenses = filterWithTag(expenses: filteredExpenses, tag: expense.tag)
//        print(expenses.count)
    }
    
    
   func filterWithTag(expenses: [Expense], tag: Tag?) -> [Expense]{
       if tag == nil { return expenses}

       return expenses.filter {expense in
           if let t = expense.tag {
               return t == tag
           } else {
               return false
           }
       }
   }
    
    func populateTest() -> [Expense]{
        var arr: [Expense] = []
        
//        expense.tag = tags[0]
        for _ in 0...5 {
            let e = Expense()
            e.mock()
//            e.tag = tags[1]
            
            arr.append(e)
        }
        arr.append(expense)
        return arr
    }
    
    
    private var sumAllExpenses: Double {
        expenses.reduce(0) { $0 + $1.value } - expense.value
    }
    
    private var thisExpensePercent: Double {
        round((expense.value / (sumAllExpenses + expense.value)) * 100) / 100
    }
    
    var body: some View {
        VStack{
            VStack{
                HStack{
                    VStack(alignment: .leading){
                        if expense.tag != nil {
                            Text("TOTAL_WITH_TAG_STRING")
                                .contentTransition(.numericText())
                                .font(.caption)
                        } else {
                            Text("OTHERS_TOTAL_STRING")
                                .contentTransition(.numericText())
                                .font(.caption)
                        }
                        Text(sumAllExpenses.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                            .font(.title)
                            .bold()
                            .contentTransition(.numericText())
                            .animation(.spring(), value: sumAllExpenses)
                    }
                    Spacer()
                }.padding(.vertical, 5)
                
                Chart {
                    SectorMark(angle: .value("TOTAL_STRING", sumAllExpenses), angularInset: 1.0)
                        .opacity(0.6)
                        .annotation(position: .overlay) {
                            Text(1 - thisExpensePercent, format: .percent)
                                .font(.footnote).bold()
                                .contentTransition(.numericText())
                                .animation(.default, value: thisExpensePercent)
                        }
                    
                    SectorMark(angle: .value("EXPENSE_STRING", expense.value), angularInset: 2.0)
                        .annotation(position: .overlay) {
                            Text(thisExpensePercent, format: .percent)
                                .font(.footnote).bold()
                                .contentTransition(.numericText())
                                .animation(.default, value: thisExpensePercent)
                        }
                }
                .padding()
                .foregroundStyle(Color.accentColor.gradient)
                .animation(.smooth(duration: 0.6), value: expenses)
                
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.tint)
                    Text("THIS_EXPENSE_STRING")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
                
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.tint)
                        .opacity(0.6)
                    Text("OTHER_EXPENSES_STRING")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
            }.opacity(showingNoDataView ? 0 : 1)
        }
        .onAppear {
            if expenses.count < 2 {
                withAnimation {
                    showingNoDataView = true
                }
            } else {
                withAnimation {
                    showingNoDataView = false
                }
            }
        }
        .overlay {
            if showingNoDataView{
                ContentUnavailableView(label: {
                    Label("NO_DATA_STRING", systemImage: "chart.pie.fill")
                }, description: {
                    Text("NO_DATA_FILTER_STRING")
                }).animation(.easeInOut, value: showingNoDataView)
                    .offset(y:15)
            }
        }
        .onAppear {
            update()
        }
        .onChange(of: filteredExpenses) { oldValue, newValue in
            update()
        }
        
    }
    
    
    func update() {
        expenses = filterWithTag(expenses: filteredExpenses, tag: expense.tag)
        
        if expenses.count < 2 {
            withAnimation {
                showingNoDataView = true
            }
        } else {
            withAnimation {
                showingNoDataView = false
            }
        }
    }
}
