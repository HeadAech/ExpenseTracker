//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse)  var expenses: [Expense]
    
    // Query to fetch today's expenses
    @Query(filter: Expense.todayPredicate(),
           sort: \Expense.date, order: .forward
    ) private var todaysExpenses: [Expense]
    
    // Calculate the sum of today's expenses
    private var todaysTotal: Double {
        todaysExpenses.reduce(0) { $0 + $1.value }
    }
    
    
    @State var newExpenseSheetPresented: Bool = false
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .top){
                //                Background
                Color.clear.edgesIgnoringSafeArea(.all)
                
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height:250)
                    .ignoresSafeArea(.all)
                
                VStack{
                    HStack{
                    
                        Text(todaysTotal, format: .currency(code: "PLN"))
                            .contentTransition(.numericText())
                            .font(.largeTitle).bold()
                            .animation(.easeInOut, value: todaysTotal)
                        
                    }
                    
                    Text("Dziś")
                        .font(.footnote)
                    
                    HStack{
                        Button("Dodaj wydatek"){
                            newExpenseSheetPresented.toggle()
                        }.buttonStyle(.borderedProminent)
                    }
                    
                    .offset(y:20)
                    
                    VStack{
                        GroupBox{
                            List{
                                ForEach(expenses){ expense in
                                    LastExpenseView(date: expense.date, name: expense.name, amount: expense.value)
                                }
                                .onDelete(perform: deleteItems)
                            }
                            .scrollDisabled(true)
                            .scrollContentBackground(.hidden)
                            .offset(y: -25)
                            
                            if !expenses.isEmpty{
                                Button("Pokaż wszystkie"){
                                    
                                }
                            }
                        } label: {
                            Label("Ostatnie", systemImage: "clock.arrow.circlepath")
                        }
                        .frame(width: 350, height: 250)
                        
                    }
                    .overlay{
                        if expenses.isEmpty{
                            ContentUnavailableView(label: {
                                Label("Brak wydatków", systemImage: "dollarsign.square.fill")
                            }, description: {
                                Text("Dodaj nowy wydatek, aby zobaczyć listę wydatków.")
                            }, actions: {
                                Button("Dodaj", action: {
                                    newExpenseSheetPresented.toggle()
                                })
                            }).animation(.easeInOut, value: expenses.isEmpty)
                        }
                    }
                    .offset(y: 70)
                    
                    
                    
                }.offset(y:20)
                                
                
                
            }
            
            
            
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                }
            }
        }
        
        .sheet(isPresented: $newExpenseSheetPresented) {
            NewExpenseSheet()
            
            .presentationDetents([.medium])
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Expense(name: "Name", date: Date(), value: 140.0)
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}

#Preview{
    NewExpenseSheet()
}

struct LastExpenseView: View {
    
    @State var date: Date
    @State var name: String
    @State var amount: Double
    
    var body: some View {
        withAnimation{
            VStack{
                HStack{
                    Text(name)
                    Spacer()
                    Text(amount, format: .currency(code: "PLN"))
                }
                HStack{
                    Text(date.formatted(date: .numeric, time: .shortened))
                        .font(.footnote)
                    Spacer()
                }
            }
            .listRowInsets(EdgeInsets())
        }
    }
}

struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = "Wydatek"
    @State private var date: Date = .now
    @State private var amount: Double = 0.00
    
    @State private var isErrorAlertPresent: Bool = false
    
    var body: some View {
        NavigationStack{
            Form{
                TextField("Nazwa", text: $name)
                DatePicker(selection: $date, label: {
                    Label("Data", systemImage: "calendar")
                })
                TextField("Kwota", value: $amount, format: .currency(code: "PLN"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Nowy wydatek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Dodaj") {
                        if amount <= 0 {
                            isErrorAlertPresent.toggle()
                            return
                        }
                        let expense = Expense(name: name, date: date, value: amount)
                        modelContext.insert(expense)
                        dismiss()
                    }
                    .alert("Kwota musi być większa niż zero.", isPresented: $isErrorAlertPresent){
                        Button("OK", role: .cancel) { }
                    }
                }
            }
        }
        
        
    }
}
