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
                        .foregroundStyle(.secondary)
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
                .presentationDragIndicator(.hidden)
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

    @State private var allTokens: [Tag] = []
    
    @State private var currentTokens: [Tag] = []
    
    @State private var filterTag: Tag?
    
    var suggestedTokens: [Tag] {
        if searchText.starts(with: "#") {
            return allTokens
        } else {
            return []
        }
    }
    
    var groupedByDate: [Date: [Expense]] {
//        Dictionary(grouping: expenses, by: {$0.date})
        Dictionary(grouping: expenses, by: { expense in
                Calendar.current.startOfDay(for: expense.date)
            })
    }
    
    var headers: [Date] {
        groupedByDate.map({ $0.key }).sorted().reversed()
    }
    
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
    
    func row(expense: Expense) -> some View {
//        Button {
//            chosenExpense = expense
//        } label: {
//            ExpenseListItem(expense: expense)
//                .contentShape(Rectangle())
//        }
//        .contentShape(Rectangle())
//        .buttonStyle(.plain)
        NavigationLink(destination: {
            ExpenseDetailsView(expense: expense, sheetDisplayMode: false)
        }, label: {
            ExpenseListItem(expense: expense)
        })
        .onAppear {
            performFetchIfNecessary(item: expense)
        }
    }
    
    private func tagBox(tag: Tag) -> some View{
        let name: String = tag.name
        let color: Color = Color(hex: tag.color) ?? .secondary
        let icon: String = tag.icon
        
        return VStack{
            
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.caption)
                
                if name == "" {
                    Text("UNTAGGED_STRING")
                        .font(.caption)
                        .foregroundColor(color.foregroundColorForBackground())
                } else {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(color.foregroundColorForBackground())
                }
            }.padding(5)
            
        }.background(
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .opacity(filterTag == tag ? 0.8 : 0.2)
            )

    }
    
    var body: some View {
        
        NavigationStack {
            
            List{
                
                if isSearchBarPresented {
                    Section {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(allTokens) {token in
                                    Button {
                                        if filterTag == token {
                                            filterTag = nil
                                        } else {
                                            filterTag = token
                                        }
                                    } label: {
                                        tagBox(tag: token)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .contentMargins(9, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned)
                    } header : {
                        Label("FILTER_STRING", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                if searchText.isEmpty && filterTag == nil {
                    ForEach(headers, id: \.self) {header in
                        
                        Section {
                            ForEach(groupedByDate[header]!) { expense in
                                row(expense: expense)
                            }
                            .onDelete(perform: deleteItems)
                            .ignoresSafeArea(.keyboard)
                        } header: {
                            if header >= Calendar.current.startOfDay(for: .now) {
                                Text("TODAY_STRING")
                            } else {
                                Text(header, style: .date)
                            }
                        }
                        
                    }
                } else {
                    ForEach(searchText.isEmpty && filterTag == nil ? expenses : filteredExpenses) { expense in
                        
                        row(expense: expense)
                        
                    }
                    .onDelete(perform: deleteItems)
                    .ignoresSafeArea(.keyboard)

                }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
            .scrollContentBackground(.hidden)
//            .if(isSearchBarPresented){view in
//                view.searchable(text: $searchText, isPresented: $isSearchBarPresented)
//            }
            
            .searchable(text: $searchText, isPresented: $isSearchBarPresented)
            
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: searchText) { oldValue, newValue in
                filterResults()
            }
            .onChange(of: expenses) { oldValue, newValue in
                filterResults()
            }
            .onChange(of: filterTag) { oldValue, newValue in
                filterResults()
            }
            .onChange(of: isSearchBarPresented, { oldV, newV in
                filterTag = nil
            })
            .overlay {
                if showingNoExpensesView{
                    ContentUnavailableView(label: {
                        Label("NO_EXPENSES_STRING", systemImage: "dollarsign.square.fill")
                    }, description: {
                        Text("NO_EXPENSES_DESCRIPTION")
                    }).animation(.easeInOut, value: showingNoExpensesView)
                        .offset(y:-15)
                }
                
                if !showingNoExpensesView && filteredExpenses.isEmpty{
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
            
                
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    searchButton
                }
            }
            
            .navigationTitle("HISTORY_STRING")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .onAppear {
            withAnimation {
                showingNoExpensesView = expenses.isEmpty
            }
            currentPage = 0
            performFetch()
            fetchTags()
            print(self.allTokens)
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
//        .fullScreenCover(item: $chosenExpense) {expense in
//            ExpenseDetailsView(expense: expense)
//        }
        
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
    
    private func fetchTags() {
        let fetchDescriptor = FetchDescriptor<Tag>()
        do {
            self.allTokens = try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error)
        }
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
//        return expenses.filter { $0.name.lowercased().localizedStandardContains(text.lowercased()) }
        var fetchDescriptor = FetchDescriptor<Expense>()
        
        if !text.isEmpty{
            fetchDescriptor.predicate = #Predicate {
                return $0.name.localizedStandardContains(text)
            }
        }
        
        fetchDescriptor.sortBy = [.init(\.date, order: .reverse)]
        
        do {
            let e = try modelContext.fetch(fetchDescriptor)
            
            if filterTag != nil {
                return e.filter {e in
                    if e.tag != nil {
                        return e.tag == filterTag
                    }
                    return false
                }
            
            } else {
                return e
            }
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
    
    private func filterResults() {
        filteredExpenses = filterSearchResults(text: searchText)
        print(filteredExpenses.count)
    }
}

#Preview {
    HistoryView()
        
}
