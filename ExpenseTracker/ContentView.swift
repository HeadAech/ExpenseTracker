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
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var isSearching: Bool = false
    
    @Environment(\.modelContext)  var modelContext
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
    
    @State var tagsViewPresented: Bool = false
    
    
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
                            
                            Text(isSummingDaily ? todaysTotal : thisMonthTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .contentTransition(.numericText())
                                .font(.largeTitle).bold()
                                .animation(.easeInOut, value: isSummingDaily ? todaysTotal : thisMonthTotal)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                        }
                        
                        Text(isSummingDaily ? "TODAY_STRING" : "THIS_MONTH_STRING")
                            .font(.footnote)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: isSummingDaily)
                        
                        
                        
//                        
//                        LastTenExpensesChart(expenses: expenses)
//                            .frame(height: 40)
//                            .padding(.horizontal, 5)
//                            .padding(.bottom, -30)
                            
                    }
                    .ignoresSafeArea(.keyboard)
                    .offset(y: 10)
                
                    

                        TabView(selection: $page) {

                            StatisticsView()
                                .tabItem {
                                    Label("STATISTICS_STRING", systemImage: "chart.bar.xaxis")
                                        .labelStyle(VerticalLabelStyle())
                                }
                                .tag(Pages.stats)
                            
                            homeView
                                .tabItem {
                                    Label("HOME_STRING", systemImage: "house.fill")
                                        .labelStyle(VerticalLabelStyle())
                                }
                                .tag(Pages.home)
                            
                            HistoryPage()
                                .tabItem {
                                    Label("HISTORY_STRING", systemImage: "clock.arrow.circlepath")
                                        .labelStyle(VerticalLabelStyle())
                                }
                                .tag(Pages.history)
                            
                        }
                        .transition(.blurReplace)
                        .animation(.smooth, value: page)
                            .tabViewStyle(.page(indexDisplayMode: .never))
//                            .indexViewStyle(.page(backgroundDisplayMode: .always))
                            
//                    }

                }
                .ignoresSafeArea(.keyboard)
             
//                END ZSTACK
            }
            
            .ignoresSafeArea(edges: .bottom)
            
            
            .safeAreaInset(edge: .bottom) {
                //            NAVBAR ITEMS
                ZStack(alignment: .bottom){
                    VStack {
                        Spacer()
                        let cutoffColor = colorScheme == .dark ? Color.black : Color.white
                        LinearGradient(gradient: Gradient(colors: [cutoffColor.opacity(0), cutoffColor.opacity(0.9)]),
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                            .frame(height: 150)
                                            .blur(radius: 5)
                    }.offset(y: 40)
                    
                    HStack{
                        navBarItem(name: "STATISTICS_STRING", icon: "chart.bar.xaxis", tab: .stats)
                        navBarItem(name: "HOME_STRING", icon: "house.fill", tab: .home)
                        navBarItem(name: "HISTORY_STRING", icon: "clock.arrow.circlepath", tab: .history)
                    }.ignoresSafeArea(.keyboard)
                    .background(
                        Capsule()
                            .fill(.clear)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    )
                    
                    .ignoresSafeArea(.keyboard)
                }
                .ignoresSafeArea(.keyboard)
            }
            
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button{
                        settingsSheetPresented.toggle()
                    } label: {
                        Label("", systemImage: "gear")
                    }
                    
                    Button {
                        tagsViewPresented.toggle()
                    } label: {
                        Image(systemName: "tag.fill")
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Button{
                        newExpenseSheetPresented.toggle()
                    } label: {
                        HStack{
                            Text("ADD_STRING")
                            Image(systemName: "plus")
                        }
                    }.buttonStyle(.bordered)
                }
            }
        }
        
        .sheet(isPresented: $tagsViewPresented) {
            TagsView()
                .presentationBackground(.thinMaterial)
        }
        
        .sheet(isPresented: $newExpenseSheetPresented) {
            
//            Old UI
//            NewExpenseSheet()
//                .presentationDetents([.medium, .large])
            
            NewExpenseView()
                .presentationDetents([.large])
        }
        
        .sheet(isPresented: $settingsSheetPresented){
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thinMaterial)
        }
        
        
        .tint(Colors().getColor(for: gradientColorIndex))
        .animation(.easeInOut, value: gradientColorIndex)
        
    }
    
    var homeView: some View {
        ScrollView {
            VStack{
                
                
                let columns = [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ]
                LazyVGrid(columns: columns, spacing: 8){
                    //    Charts

                    GroupBox{
                        LastAndCurrentMonthExpensesChart()
                        
                    } label: {
                        Label("COMPARISON_STRING", systemImage: "chart.bar.xaxis")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 200)
                    .onTapGesture {
                        withAnimation{
                            page = .stats
                        }
                    }
                    
                    GroupBox{
                        BudgetView()
                    } label: {
                        Label("BUDGET_STRING", systemImage: "dollarsign")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 200)
                   
                }.padding(.horizontal, 20)
                
                
                Section {
                    
                    GroupBox{
                        MostExpensiveCategoryView(expenses: expenses)
                            .frame(minHeight: 150)
                    } label: {
                        Label("MOST_EXPENSIVE_STRING", systemImage: "banknote.fill")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 200)
                    .padding(.horizontal, 20)
                    
//                        GroupBox{
//                            BudgetView()
//                        } label: {
//                            Label("BUDGET_STRING", systemImage: "dollarsign")
//                        }
//                        .frame(minWidth: 177, maxWidth: 177, minHeight: 200)
                    
                } header: {
                    HStack {
                        Image(systemName: "chevron.compact.down")
                            .foregroundStyle(.secondary)
                    }.padding(.horizontal, 23)
                        .padding(.vertical, 10)
                }
            }
            
            Spacer()
                .padding(.top, 80)
        }
        .padding(.top, 70)
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
        
    }
    
    func navBarItem(name: LocalizedStringResource, icon: String, tab: Pages) -> some View {
        
           Button {
               page = tab
           } label: {

               VStack {
                   if page == tab {
                       Label{
                           Text(name)
                       } icon: {
                           Image(systemName: icon)
                       }
//                       Text(name)
                           .frame(width: 70, height: 20)
                           .padding()
//                           .foregroundColor(.white)
                           .background(
                            Capsule()
                                .foregroundColor(Colors().getColor(for: gradientColorIndex).opacity(0.8))
                           )
                           .labelStyle(VerticalLabelStyle())
                           .matchedGeometryEffect(id: "box", in: namespace)
                           .transition(.blurReplace)

                   } else {
                       Image(systemName: icon)
                           .frame(width: 30, height: 20)
                           .padding()
                           .transition(.symbolEffect)
                   }
               }
               .transition(.scale)
               .animation(.spring(), value: page)
           }
           .buttonStyle(.plain)
           .padding(.vertical, 5)
           .padding(.horizontal, 5)
               
       }
    
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
        .modelContainer(for: Tag.self, inMemory: true)
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
