//
//  MostExpensiveaCategoryView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 18/09/2024.
//

import SwiftUI
import SwiftData

struct MostExpensiveCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    var expenses: [Expense]?
    
    @State var mostPaidTagName: String?
    @State var mostPaidTag: Tag?
    
    @State private var showingNoDataView: Bool = false
    
    func iconThumbnail(color: Color, icon: String) -> some View {
        ZStack{
            Circle()
                .fill(color.gradient)
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(20)
                .frame(width: 60, height: 60)
                .foregroundColor(color.foregroundColorForBackground())
        }.padding(-10)
    }
    
    var body: some View {
        HStack {
            
            if mostPaidTag != nil {
                
                
                VStack(alignment: .leading) {
                    Text("YOU_SPEND_THE_MOST_THIS_MONTH_IN_STRING")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                    
                    HStack{
                        iconThumbnail(color: Color(hex: mostPaidTag!.color) ?? .red, icon: mostPaidTag!.icon)
                        
                        Text(mostPaidTagName!)
                            .font(.headline)
                            .bold()
                    }
                }.padding(.horizontal, 2)
                
                Spacer()
                Spacer()
                
                MostPaidCategoryChart(expenses: expenses, tag: mostPaidTag!)
                    .padding()
                    
                
            } else {
                ContentUnavailableView(label: {
                    Label("NO_DATA_STRING", systemImage: "chart.pie.fill")
                }, description: {
                    Text("ADD_EXPENSES_STATISTICS_DESCRIPTION")
                }).animation(.easeInOut, value: showingNoDataView)
                    .offset(y:15)
            }
        }
        .onAppear {
            mostPaidTagName = getMostPaidTag(context: modelContext)?.name
            mostPaidTag = getMostPaidTag(context: modelContext)
            withAnimation {
                showingNoDataView = mostPaidTag == nil
            }
        }
        .onChange(of: expenses) { oldV, newV in
            mostPaidTagName = getMostPaidTag(context: modelContext)?.name
            mostPaidTag = getMostPaidTag(context: modelContext)
            withAnimation {
                showingNoDataView = mostPaidTag == nil
            }
        }
    }
    // Function to fetch all expenses and compute the most paid tag
    func getMostPaidTag(context: ModelContext) -> Tag? {
        // Fetch all expenses from the database
        var request = FetchDescriptor<Expense>()
        
        // Get the current date
        let calendar = Calendar.current
        let now = Date()
        
        // Compute the start of the current month (e.g., 1st September)
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Compute the end of the current month (e.g., 30th September)
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        request.predicate = #Predicate<Expense> { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }

        
        let expenses: [Expense]
        
        do {
            expenses = try context.fetch(request)
        } catch {
            print("Failed to fetch expenses: \(error)")
            return nil
        }
        
        // Create a dictionary to accumulate total paid amount by tag
        var tagTotals: [Tag: Double] = [:]
        
        for expense in expenses {
            let tag = expense.tag
            
            if tag == nil {
                continue
            }
            
            let amount = expense.value

            // Add amount to the corresponding tag
            tagTotals[tag!, default: 0.0] += amount
        }
        
        // Find the tag with the maximum paid amount
        let mostPaidTag = tagTotals.max { $0.value < $1.value }?.key
        
        return mostPaidTag
    }
}

#Preview {
    MostExpensiveCategoryView()
}
