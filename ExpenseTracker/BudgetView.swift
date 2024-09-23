//
//  BudgetView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("settings:monthlyBudget") private var monthlyBudget: Double = 100.0
    
    @Query(filter: Expense.currentMonthPredicate()) private var currentMonthExpenses: [Expense]

    // Calculate the sum of today's expenses
    private var currentMonthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.value }
    }
    
    @State var changeBudgetSheetPresented: Bool = false
    @State private var isShowingPieChart: Bool = false
    
    private var remainingBudget: Double {
        monthlyBudget - currentMonthTotal
    }
    
    var body: some View {
        VStack{

            Spacer()
            
            Text(remainingBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .contentTransition(.numericText())
                .animation(.easeInOut, value: remainingBudget)
                .font(.headline)
                .foregroundStyle(remainingBudget <= 0 ? .red : .primary)
//            Text("Pozostało")
//                .font(.caption)
            
            if isShowingPieChart{
                BudgetUsageView()
                    .transition(.scale)
            }
            
            Spacer()
            
            Button{
                changeBudgetSheetPresented.toggle()
            } label: {
                Label("CHANGE_STRING", systemImage: "arrow.2.circlepath")
            }
            .onChange(of: remainingBudget) { oldValue, newValue in
                update()
            }
            .onAppear{
                update()
            }
        }
        .sheet(isPresented: $changeBudgetSheetPresented) {
            ChangeBudgetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        
    }
    
    func update() {
        if remainingBudget != monthlyBudget && remainingBudget > 0{
            withAnimation{
                isShowingPieChart = true
            }
        } else {
            withAnimation{
                isShowingPieChart = false
            }
        }
    }
}

struct ChangeBudgetView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("settings:monthlyBudget") private var monthlyBudget: Double = 100.0
    
    
    @State private var amount: Double = 0
    @State private var amountString: String = "0"
    @FocusState private var budgetFocused: Bool
    
    @State private var isErrorAlertPresent: Bool = false
    @State private var errorAlertMessage: LocalizedStringResource = Error.AMOUNT_LESS_THAN_ZERO.title
    
    var clearButton: some View {
        Button(role: .destructive) {
            amountString = "0"
        } label: {
            Label("CLEAR_STRING", systemImage: "clear.fill")
        }
        .buttonStyle(.bordered)
    }
    
    var body: some View {
        NavigationStack{
            TextField("", text: $amountString).opacity(0).frame(height: 0).focused($budgetFocused)
                .keyboardType(.decimalPad)
            
            VStack {
                
                amountView
                    .onChange(of: amountString) { oldValue, newValue in
                        updateAmount(from: newValue)
                    }
                    .onTapGesture {
                        withAnimation{
                            budgetFocused = true
                        }
                    }
                    .onAppear {
                        withAnimation {
                            let parts = String(monthlyBudget).split(separator: ".")
                            
                            if parts[1].count == 1 {
                                updateAmount(from: String(monthlyBudget * 10))
                            }else{
                                updateAmount(from: String(monthlyBudget))
                            }
                            
                            budgetFocused = true
                        }
                        
                    }
                
                clearButton
                
                Spacer()
                
            }
            
            .navigationTitle("CHANGE_MONTHLY_BUDGET_STRING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel){
                        dismiss()
                    } label: {
                        Text("CANCEL_STRING")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if amount <= 0 {
                            errorAlertMessage = Error.AMOUNT_LESS_THAN_ZERO.title
                            isErrorAlertPresent.toggle()
                            return
                        }
                        UserDefaults.standard.set(amount, forKey: "settings:monthlyBudget")
                        dismiss()
                    } label: {
                        Text("DONE_STRING")
                    }
                }
            }
        }
        .alert(Text(errorAlertMessage), isPresented: $isErrorAlertPresent){
            Button("OK", role: .cancel) { }
        }
        
        .presentationBackground(.thinMaterial)
        
    }
    
    private var amountView: some View {
        
        Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            .font(.largeTitle)
            .bold()
            .contentTransition(.numericText())
            .animation(.smooth(), value: amount)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .truncationMode(.tail)
//            .underlineTextField(color: .accentColor, isActive: amountFocused)
            .foregroundStyle(budgetFocused ? Color.accentColor : Color.primary)
            .animation(.spring(duration: 0.2), value: budgetFocused)
        
    }
    
    // Updates the amount by building up from the input string
    private func updateAmount(from newValue: String) {
        // Allow only digits
        let filtered = newValue.filter { "0123456789".contains($0) }
        
        if let numericValue = Int(filtered) {
            // Update amount as an integer to shift the decimal place
            amountString = String(numericValue)
        } else {
            amountString = "0.00"
        }
        
        amount = (Double(amountString) ?? 0.0) / 100
    }
    
    
}

#Preview {
    ChangeBudgetView()
}
