//
//  HistoryView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 18/09/2024.
//

import SwiftUI
import SwiftData

struct HistoryPage: View {
    
    @Environment(\.modelContext)  var modelContext
    @Query(sort: \Expense.date, order: .reverse)  var expenses: [Expense]
    
    @State private var showingNoExpensesView: Bool = false
    
    @State private var isHistorySheetPresented: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("HISTORY_STRING")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()

            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, -5)
            ScrollView{
                GroupBox{
                    LastExpensesView()
                    if showingNoExpensesView{
                        ContentUnavailableView(label: {
                            Label("NO_EXPENSES_STRING", systemImage: "dollarsign.square.fill")
                        }, description: {
                            Text("NO_EXPENSES_DESCRIPTION")
                        }).animation(.easeInOut, value: showingNoExpensesView)
                            .frame(minWidth: 250)
                    }
                    if !expenses.isEmpty{
                        Button{
                            isHistorySheetPresented.toggle()
                        } label: {
                            Label("SHOW_ALL_STRING", systemImage: "dollarsign.arrow.circlepath")
                        }
                        .padding(.top, 5)
                    }
                } label: {
                    Label("RECENT_STRING", systemImage: "clock.arrow.circlepath")
                }
                         
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .frame(maxHeight: 400)
                
                Spacer()
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
        
        .sheet(isPresented: $isHistorySheetPresented) {
            HistoryView()
                .presentationDetents([.large, .medium])
        }
    }
    
}

struct HistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
//    @Binding var isSearching: Bool
    
    @State private var expenses: [Expense] = []
    
    @State private var filteredExpenses: [Expense] = []
    
    @State private var chosenExpense: Expense?
    
    @State private var searchText: String = ""
    
    @State private var isSearchBarPresented: Bool = false
    
    @State private var showingNoExpensesView: Bool = false
    
    @State private var currentPage: Int = 0
    
    private var expensesCount: Int {
        let fetchDescriptor = FetchDescriptor<Expense>()
        do {
            return try modelContext.fetchCount(fetchDescriptor)
        } catch {
            print(error)
            return 0
        }
        
    }
    
//    private var test: [Expense]  {
//        var ex: [Expense] = []
//        
//        for _ in 0..<10 {
//            let e = Expense()
//            e.mock()
//            ex.append(e)
//        }
//        return ex
//    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding()
    }
    
    private var searchButton: some View {
        Button {
//            withAnimation{
                isSearchBarPresented.toggle()
//            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding()
    }
    
    
    var body: some View {
        
        NavigationStack {
            
            List{
                ForEach(searchText.isEmpty ? expenses : filteredExpenses) { expense in
                    Button {
                        chosenExpense = expense
                    } label: {
                        ExpenseListItem(expense: expense)
                            .contentShape(Rectangle())
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .onAppear {
                        performFetchIfNecessary(item: expense)
                    }
                    
                }
                .onDelete(perform: deleteItems)
                .ignoresSafeArea(.keyboard)
                
            }
            .ignoresSafeArea(.keyboard)
            .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 50, trailing: 0))
            .scrollContentBackground(.hidden)
//            .if(isSearchBarPresented){view in
//                view.searchable(text: $searchText, isPresented: $isSearchBarPresented)
//            }
            .searchable(text: $searchText, isPresented: $isSearchBarPresented, placement: .navigationBarDrawer)
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: searchText) { oldValue, newValue in
                filteredExpenses = filterSearchResults(text: searchText)
            }
            .onChange(of: expenses) { oldValue, newValue in
                filteredExpenses = filterSearchResults(text: searchText)
            }
            .overlay {
                if showingNoExpensesView{
                    ContentUnavailableView(label: {
                        Label("NO_EXPENSES_STRING", systemImage: "dollarsign.square.fill")
                    }, description: {
                        Text("NO_EXPENSES_DESCRIPTION")
                    }).animation(.easeInOut, value: showingNoExpensesView)
                        .offset(y:-15)
                }
                
                if !showingNoExpensesView && !searchText.isEmpty && filteredExpenses.isEmpty{
                    ContentUnavailableView(label: {
                        Label("NO_EXPENSES_STRING", systemImage: "dollarsign.square.fill")
                    }, description: {
                        Text("NO_DATA_FILTER_STRING")
                    })
                        .offset(y:-15)
                        .animation(.easeInOut, value: filteredExpenses.isEmpty)
                }
            }
            
//
//            .navigationTitle("HISTORY_STRING")
//            .navigationBarTitleDisplayMode(.large)
//            
            Spacer()
            
                
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    searchButton
                }
            }
            
            .navigationTitle("HISTORY_STRING")
            .navigationBarTitleDisplayMode(.large)
            
        }
        .onAppear {
            withAnimation {
                showingNoExpensesView = expenses.isEmpty
            }
            currentPage = 0
            performFetch()
        }
        .onChange(of: expensesCount, { oldV, newV in
            currentPage = 0
            performFetch()
        })
        .onChange(of: expenses) { oldValue, newValue in
            withAnimation {
                showingNoExpensesView = expenses.isEmpty
            }
        }
        .onDisappear{
//            withAnimation{
                isSearchBarPresented = false
//            }
        }
        .fullScreenCover(item: $chosenExpense) {expense in
            ExpenseDetailsView(expense: expense)
        }
        
    }
    
    var topBar: some View {
        HStack {
            Text("HISTORY_STRING")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            if !showingNoExpensesView{
                searchButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .padding(.bottom, -5)
        .animation(.spring(), value: isSearchBarPresented)
    }
    
    private func performFetch(currentPage: Int = 0) {
        var fetchDescriptor = FetchDescriptor<Expense>()
        fetchDescriptor.fetchLimit = 15 + (currentPage * 15)
//        fetchDescriptor.fetchOffset = currentPage * 10
        fetchDescriptor.sortBy = [.init(\.date, order: .reverse)]
        
        do {
            self.expenses = try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error)
        }
        
    }
    
    private func performFetchAll() {
        var fetchDescriptor = FetchDescriptor<Expense>()
        fetchDescriptor.sortBy = [.init(\.date, order: .reverse)]
        
        do {
            self.expenses = try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error)
        }
        
    }
    
    func performFetchIfNecessary(item: Expense) {
        if let lastItem = expenses.last, lastItem == item{
            currentPage += 1
            performFetch(currentPage: currentPage)
        }
    }
    
    func filterSearchResults(text: String) -> [Expense] {
        if text.isEmpty{
            return expenses
        }
        
//        return expenses.filter { $0.name.lowercased().localizedStandardContains(text.lowercased()) }
        var fetchDescriptor = FetchDescriptor<Expense>()
        fetchDescriptor.predicate = #Predicate {
            $0.name.localizedStandardContains(text)
        }
        fetchDescriptor.sortBy = [.init(\.date, order: .reverse)]
        
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error)
            return expenses
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
    HistoryView()
        
}
