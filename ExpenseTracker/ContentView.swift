//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
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
                    
                        Text(isSummingDaily ? todaysTotal : thisMonthTotal, format: .currency(code: "PLN"))
                            .contentTransition(.numericText())
                            .font(.largeTitle).bold()
                            .animation(.easeInOut, value: isSummingDaily ? todaysTotal : thisMonthTotal)
                        
                    }
                    
                    Text(isSummingDaily ? "Dziś" : "Ten miesiąc")
                        .font(.footnote)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: isSummingDaily)
                    
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
                                NavigationLink{
                                    AllExpensesView()
//                                        .navigationTransition(.automatic)
                                } label: {
                                    Label("Pokaż wszystkie", systemImage: "dollarsign.arrow.circlepath")
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
                                .offset(y:15)
                        }
                    }
                    .offset(y: 70) 
                    
                }.offset(y:20)
                                
            }

            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button{
                        settingsSheetPresented.toggle()
                    } label: {
                        Label("", systemImage: "gear")
                    }
                }
            }
        }
        
        .sheet(isPresented: $newExpenseSheetPresented) {
            NewExpenseSheet()
            
            .presentationDetents([.medium])
        }
        
        .sheet(isPresented: $settingsSheetPresented){
            SettingsView()
            .presentationDetents([.fraction(0.3)])
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
//
//#Preview{
//    NewExpenseSheet()
//}

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
    
    @State var selectedPhoto: PhotosPickerItem?
    @State var selectedPhotoData: Data?
    
    var body: some View {
        NavigationStack{
            Form{
                HStack{
                    Text("Nazwa")
                    TextField("Nazwa", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                HStack{
//                    Label("Data", systemImage: "calendar")
                    Text("Data")
                    DatePicker("", selection: $date)
                }
                HStack{
                    Text("Kwota")
                    TextField("Kwota", value: $amount, format: .currency(code: "PLN"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onTapGesture {
                            
                        }
                }
                Section("Zdjęcie"){

                        if let selectedPhotoData,
                           let uiImage = UIImage(data: selectedPhotoData) {
                            HStack{
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                            }
                        }

                            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()){
                                Label("Dodaj zdjęcie", systemImage: "photo")
                            }

                        if selectedPhotoData != nil {
                            Button(role: .destructive){
                                withAnimation{
                                    selectedPhoto = nil
                                    selectedPhotoData = nil
                                    
                                }
                            } label: {
                                Label("Usuń zdjęcie", systemImage: "trash")
                                    .foregroundStyle(.red)
                            }
                        }

                }
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
                        if selectedPhotoData != nil {
                            expense.image = selectedPhotoData
                        }
                        withAnimation{
                            modelContext.insert(expense)
                            dismiss()
                        }
                    }
                    .alert("Kwota musi być większa niż zero.", isPresented: $isErrorAlertPresent){
                        Button("OK", role: .cancel) { }
                    }
                }
            }
            .task(id: selectedPhoto){
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self){
                    selectedPhotoData = data
                }
            }
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
                    NavigationLink(destination: {
                        if let selectedPhotoData = expense.image, let uiImage = UIImage(data: selectedPhotoData) {
                            ImageViewer(image: uiImage)
                        }
                    }) {
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
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }
                    }
                    
                    
                }
            }
        }
        .navigationTitle("Wszystkie wydatki")
        .navigationBarTitleDisplayMode(.large)
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
