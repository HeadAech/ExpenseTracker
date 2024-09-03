//
//  ExpensesView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI
import SwiftData

struct LastExpensesView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse)  var expenses: [Expense]
    
    var body: some View {
        List{
//            Testing
//            LastExpenseItem(date: .now, name: "Wydatek", amount: 10000)
            ForEach(expenses){ expense in
                LastExpenseItem(date: expense.date, name: expense.name, amount: expense.value)
                    .contextMenu{
                        Button(role: .destructive){
                            withAnimation {
                                modelContext.delete(expense)
                            }
                        } label: {
                            Label("Usuń", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteItems)
            
        }
        .padding(-10)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .offset(y: -25)
        .animation(.smooth, value: expenses)
        
        
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}


struct LastExpenseItem: View {
    
    @State var date: Date
    @State var name: String
    @State var amount: Double
    
    var body: some View {
        
            VStack{
                HStack{
                    Text(name)
                    Spacer()
                    Text(amount, format: .currency(code: "PLN"))
                        .font(.headline)
                        .lineLimit(1)
                      .truncationMode(.tail)
                }
                HStack{
                    Text(date.formatted(date: .numeric, time: .shortened))
                        .font(.footnote)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        
    }
}


struct AllExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var showingNoExpensesView: Bool = true
    
    var body: some View {
        NavigationStack{
//            HStack{
//                Text("Wszystkie wydatki")
//                    .font(.title)
//                Spacer()
//            }
            List{
                ForEach(expenses) { expense in
                    if expense.image != nil {
                        NavigationLink(destination: {
                            if let selectedPhotoData = expense.image, let uiImage = UIImage(data: selectedPhotoData) {
                                ImageViewer(image: uiImage)
                            }
                        }) {
                            ExpenseListItem(expense: expense)
                        }
                        
                    } else {
                        ExpenseListItem(expense: expense)
                    }
                    
                }
                .onDelete(perform: deleteItems)
                
            }
            //                    .listStyle(PlainListStyle())
            .padding(-30)
            .scrollContentBackground(.hidden)
            
            .frame(height: UIScreen.screenHeight/2)
            .overlay {
                if showingNoExpensesView{
                    ContentUnavailableView(label: {
                        Label("Brak wydatków", systemImage: "dollarsign.square.fill")
                    }, description: {
                        Text("Dodaj nowy wydatek, aby zobaczyć listę wydatków oraz statystyki.")
                    }).animation(.easeInOut, value: showingNoExpensesView)
                        .offset(y:15)
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
            .animation(.smooth, value: expenses)
        
        }.padding(20)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}

struct ExpenseListItem: View {
    @Environment(\.modelContext) private var modelContext
    @State var expense: Expense
    
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                Text(expense.name)
                    .font(.headline)
                
                Text(expense.value, format: .currency(code: "PLN"))
                    .bold()
                
                Text(expense.date, style: .relative)
                    .font(.caption)
            }
            Spacer()
            if let selectedPhotoData = expense.image, let uiImage = UIImage(data: selectedPhotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 60, height: 60, alignment: .trailing)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .contextMenu{
            Button(role: .destructive){
                withAnimation {
                    modelContext.delete(expense)
                }
            } label: {
                Label("Usuń", systemImage: "trash")
            }
        }

    }
}

struct ExpenseDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State var expense: Expense
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .top){
                Color.clear.edgesIgnoringSafeArea(.all)
                
                if let selectedPhotoData = expense.image, let uiImage = UIImage(data: selectedPhotoData) {
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .ignoresSafeArea(.all)
                    //We can use the LinearGradient in the mask modifier to fade it top to bottom
                        .mask(LinearGradient(gradient: Gradient(stops: [
                            .init(color: .black, location: 0),
                            .init(color: .clear, location: 1),
                            .init(color: .black, location: 1),
                            .init(color: .clear, location: 1)
                        ]), startPoint: .top, endPoint: .bottom))
                        .padding()
                        .frame(width: .infinity, height: 250)
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.clear]), startPoint: .top, endPoint: .bottom)
                        .frame(height:250)
                        .ignoresSafeArea(.all)
                }
                
                
            }.ignoresSafeArea(.all)
        }
    }
}


#Preview {
    LastExpensesView()
}
