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
            
            Text(remainingBudget, format: .currency(code: "PLN"))
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
                .presentationDetents([.fraction(0.3)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thinMaterial)
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
    
    @State private var budget: String = "0,00"
    @FocusState private var budgetFocused: Bool
    
    
    var body: some View {
        NavigationStack{
            Form{
                HStack{
                    Text("BUDGET_STRING")
                    TextField("BUDGET_STRING", text: $budget)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: budget) { oldValue, newValue in
                            updateAmount(from: newValue)
                        }
                        .focused($budgetFocused)
                    Text("PLN")
                        
                }
                .onAppear{
                    budget = String(monthlyBudget * 10)
                    budgetFocused.toggle()
                }
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
                        monthlyBudget = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0
                        UserDefaults.standard.set(monthlyBudget, forKey: "settings:monthlyBudget")
                        dismiss()
                    } label: {
                        Text("DONE_STRING")
                    }
                }
            }
        }
        
    }
    
    // Updates the amount by building up from the input string
    private func updateAmount(from newValue: String) {
        // Allow only digits
        let filtered = newValue.filter { "0123456789".contains($0) }
        
        if let numericValue = Int(filtered) {
            // Update amount as an integer to shift the decimal place
            budget = String(numericValue)
            budget = formattedAmount()
        } else {
            budget = "0,00"
        }
    }
    
    // Converts the current amount to a formatted string with 2 decimal places
    private func formattedAmount() -> String {
        if let value = Double(budget) {
            return String(format: "%.2f", value / 100).replacingOccurrences(of: ".", with: ",")
            
        }
        return "0,00"
    }
}

#Preview {
    ChangeBudgetView()
}
