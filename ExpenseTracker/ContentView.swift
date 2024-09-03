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
                        
                        Text(isSummingDaily ? "Dziś" : "Ten miesiąc")
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
