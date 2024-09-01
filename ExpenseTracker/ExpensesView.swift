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
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .offset(y: -25)
        
        if !expenses.isEmpty{
            NavigationLink{
                AllExpensesView()
            } label: {
                Label("Pokaż wszystkie", systemImage: "dollarsign.arrow.circlepath")
            }
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


struct LastExpenseItem: View {
    
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


struct AllExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    var body: some View {
        NavigationStack {
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
            
        }
        .navigationTitle("Wszystkie wydatki")
        .navigationBarTitleDisplayMode(.large)
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
