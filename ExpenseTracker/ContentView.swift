//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData
import PhotosUI

enum Pages {
    case home, stats, history
}

struct ContentView: View {
    @Namespace private var namespace
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse)  var expenses: [Expense]
    
    // Query to fetch today's expenses
    @Query(filter: Expense.todayPredicate(),
           sort: \Expense.date, order: .forward
    ) private var todaysExpenses: [Expense]
    
    // Query to fetch today's expenses
    @Query(filter: Expense.currentMonthPredicate(),
           sort: \Expense.date, order: .forward
    ) private var thisMonthExpenses: [Expense]
    
    // Calculate the sum of today's expenses
    private var todaysTotal: Double {
        todaysExpenses.reduce(0) { $0 + $1.value }
    }
    
    // Calculate the sum of today's expenses
    private var thisMonthTotal: Double {
        thisMonthExpenses.reduce(0) { $0 + $1.value }
    }
    
    @State var newExpenseSheetPresented: Bool = false
    @State var settingsSheetPresented: Bool = false
    
    
    @AppStorage("settings:isSummingDaily") var isSummingDaily: Bool = true
    
    private var gradientColors: [Int: Color] = Colors().gradientColors
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var showingNoExpensesView: Bool = true
    
//    Default page 
    @State private var page: Pages = .home
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .top){
                //                Background
                Color.clear.edgesIgnoringSafeArea(.all)
                
                LinearGradient(gradient: Gradient(colors: [Colors().getColor(for: gradientColorIndex).opacity(0.8), Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height:250)
                    .ignoresSafeArea(.all)
                    .animation(.easeInOut, value: gradientColorIndex)
                
                VStack{
                    VStack{
                        HStack{
                            
                            Text(isSummingDaily ? todaysTotal : thisMonthTotal, format: .currency(code: "PLN"))
                                .contentTransition(.numericText())
                                .font(.largeTitle).bold()
                                .animation(.easeInOut, value: isSummingDaily ? todaysTotal : thisMonthTotal)
                            
                        }
                        
                        Text(isSummingDaily ? "today" : "this_month")
                            .font(.footnote)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: isSummingDaily)
                        
                        HStack{
                            
                            
                        }
                    }.offset(y: 0)
                    
                    
                    HStack{
                        Button {
                            withAnimation{
                                page = .stats
                            }
                        } label: {
                            Label("Statystyki", systemImage: "chart.bar.xaxis")
                                .labelStyle(VerticalLabelStyle())
                        }
                        .buttonStyle(NavigationButtonStyle(isPressed: page == .stats))
                        
                        Button {
                            withAnimation{
                                page = .home
                            }
                        } label: {
                            Label("Główna", systemImage: "house.fill")
                                .labelStyle(VerticalLabelStyle())
                        }
                        .buttonStyle(NavigationButtonStyle(isPressed: page == .home))
                        
                        Button {
                            withAnimation{
                                page = .history
                            }
                        } label: {
                            Label("Historia", systemImage: "clock.arrow.circlepath")
                                .labelStyle(VerticalLabelStyle())
                        }
                        .buttonStyle(NavigationButtonStyle(isPressed: page == .history))
                    }.offset(y: 20)
                    
                    LazyVStack {
                        if page == .home {
                            LazyVStack{
                                
                                GroupBox{
                                    LastExpensesView()
                                    
                                    if !expenses.isEmpty{
                                        Button{
                                            withAnimation{
                                                page = .history
                                            }
                                        } label: {
                                            Label("Pokaż wszystkie", systemImage: "dollarsign.arrow.circlepath")
                                        }
                                    }
                                } label: {
                                    Label("Ostatnie", systemImage: "clock.arrow.circlepath")
                                }
                                .overlay{
                                    if showingNoExpensesView{
                                        ContentUnavailableView(label: {
                                            Label("Brak wydatków", systemImage: "dollarsign.square.fill")
                                        }, description: {
                                            Text("Dodaj nowy wydatek, aby zobaczyć listę wydatków oraz statystyki.")
                                        }, actions: {
                                            Button("Dodaj", action: {
                                                newExpenseSheetPresented.toggle()
                                            })
                                        }).animation(.easeInOut, value: showingNoExpensesView)
                                            .offset(y:15)
                                    }
                                }
                                .frame(width: 350, height: 250)
                                .onTapGesture {
                                    withAnimation {
                                        page = .history
                                    }
                                }
                                
                                //    Charts
                                LazyHStack {
                                    
                                    GroupBox{
                                        LastAndCurrentMonthExpensesChart()
                                        
                                    } label: {
                                        Label("Porównanie", systemImage: "chart.bar.xaxis")
                                    }
                                    .frame(width: 172, height: 200)
                                    .onTapGesture {
                                        withAnimation{
                                            page = .stats
                                        }
                                    }
                                    
                                    GroupBox{
                                        BudgetView()
                                    } label: {
                                        Label("Budżet", systemImage: "dollarsign")
                                    }
                                    .frame(width: 172, height: 200)
                                    
                                }
                            }
                            .onChange(of: expenses.isEmpty, { oldValue, newValue in
                                withAnimation{
                                    showingNoExpensesView = expenses.isEmpty
                                }
                            })
                            .onAppear {
                                withAnimation {
                                    showingNoExpensesView = expenses.isEmpty
                                }
                            }
                            .transition(.blurReplace)
                            .animation(.easeInOut, value: page)
                            
                            
                        } else if page == .stats {
                            StatisticsView()
                                .transition(.blurReplace)
                                .animation(.easeInOut, value: page)
                            
                        } else if page == .history {
                            AllExpensesView()
                                .transition(.blurReplace)
                                .animation(.easeInOut, value: page)
                        }
                        
                    }
                    .offset(y:30)
                }
                
            }
            
            .toolbar{
                ToolbarItem(placement: .topBarLeading) {
                    Button{
                        settingsSheetPresented.toggle()
                    } label: {
                        Label("", systemImage: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        newExpenseSheetPresented.toggle()
                    } label: {
                        HStack{
                            Text("Dodaj")
                            Image(systemName: "plus")
                        }
                    }.buttonStyle(.bordered)
                }
            }
        }
        
        .sheet(isPresented: $newExpenseSheetPresented) {
            NewExpenseSheet()
            
                .presentationDetents([.medium])
        }
        
        .sheet(isPresented: $settingsSheetPresented){
            SettingsView()
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
        .tint(Colors().getColor(for: gradientColorIndex))
        .animation(.easeInOut, value: gradientColorIndex)
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
//
//#Preview{
//    NewExpenseSheet()
//}


struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.headline)
            configuration.title.font(.footnote)
        }
    }
}

struct NavigationButtonStyle: ButtonStyle {
    
    var isPressed: Bool
    
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 70, height: 20)
            .padding()
            .background(isPressed ?
                        Colors().getColor(for: gradientColorIndex).opacity(0.8)
                        : Colors().getColor(for: gradientColorIndex).opacity(0.4))
            .clipShape(.buttonBorder)
    }
}
