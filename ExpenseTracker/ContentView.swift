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
    
    private var gradientColors: [Int: Color] = Colors().gradientColors
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @State private var showingNoExpensesView: Bool = true
    
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
                    
                    LazyVStack{
                        GroupBox{
                            LastExpensesView()
                        } label: {
                            Label("Ostatnie", systemImage: "clock.arrow.circlepath")
                        }
                        .frame(width: 350, height: 250)
                        
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
                    .offset(y: 50)
                    
//                    Charts
                    LazyHStack {
                        GroupBox{
                            LastAndCurrentMonthExpensesChart()
                        } label: {
                            Label("Porównanie", systemImage: "chart.bar.xaxis")
                        }
                        .frame(width: 172, height: 200)
                        
                        GroupBox{
                            BudgetView()
                        } label: {
                            Label("Budżet", systemImage: "dollarsign")
                        }
                        .frame(width: 172, height: 200)
                        
                    }.offset(y: -25)
                    
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


struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = "Wydatek"
    @State private var date: Date = .now
    @State private var amount: String = "0,00"
    
    @State private var errorAlertMessage: String = "Kwota musi być większa niż zero."
    @State private var isErrorAlertPresent: Bool = false
    
    @State var selectedPhoto: PhotosPickerItem?
    @State var selectedPhotoData: Data?
    
    @FocusState var amountFocused: Bool
    
    @State private var showCameraPicker: Bool = false
    @State private var showPhotosPicker: Bool = false
    
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
                    TextField("Kwota", text: $amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onTapGesture {
                            
                        }
                        .onChange(of: amount) { newValue in
                            updateAmount(from: newValue)
                        }
                        .focused($amountFocused)
                    Text("PLN")
                        
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

                            
                    Menu{
//                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()){
//                            Label("Dodaj zdjęcie", systemImage: "photo")
//                        }
                        Button {
                            showPhotosPicker.toggle()
                        } label: {
                            Label("Wybierz zdjęcie", systemImage: "photo")
                        }
                        
                        Button {
                            showCameraPicker.toggle()
                        } label: {
                            Label("Zrób zdjęcie", systemImage: "camera.fill")
                        }
                    } label: {
                        Label("Dodaj zdjęcie...", systemImage: "photo.badge.plus.fill")
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
            .onAppear {
                amountFocused.toggle()
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
                        let doubleAmount = Double(amount.replacingOccurrences(of: ",", with: "."))
                        if doubleAmount ?? 0 <= 0 {
                            errorAlertMessage = "Kwota musi być większa niż zero."
                            isErrorAlertPresent.toggle()
                            return
                        }
                        if date > Date() {
                            errorAlertMessage = "Data nie może być z przyszłości."
                            isErrorAlertPresent.toggle()
                            return
                        }
                        let expense = Expense(name: name, date: date, value: doubleAmount ?? 0)
                        if selectedPhotoData != nil {
                            expense.image = selectedPhotoData
                        }
                        withAnimation{
                            modelContext.insert(expense)
                            dismiss()
                        }
                    }
                    .alert(errorAlertMessage, isPresented: $isErrorAlertPresent){
                        Button("OK", role: .cancel) { }
                    }
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
            .task(id: selectedPhoto){
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self){
                    selectedPhotoData = data
                }
            }
            
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView() { image in
                selectedPhotoData = image.jpegData(compressionQuality: 0.8)
            }
        }
        
    }
    // Updates the amount by building up from the input string
    private func updateAmount(from newValue: String) {
        // Allow only digits
        let filtered = newValue.filter { "0123456789".contains($0) }
        
        if let numericValue = Int(filtered) {
            // Update amount as an integer to shift the decimal place
            amount = String(numericValue)
            amount = formattedAmount()
        } else {
            amount = "0,00"
        }
    }
    
    // Converts the current amount to a formatted string with 2 decimal places
    private func formattedAmount() -> String {
        if let value = Double(amount) {
            return String(format: "%.2f", value / 100).replacingOccurrences(of: ".", with: ",")
            
        }
        return "0,00"
    }

}
