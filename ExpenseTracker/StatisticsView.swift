//
//  StatisticsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI

struct StatisticsView: View {
    
    var body: some View {
        LazyVStack{
            GroupBox{
                LastAndCurrentMonthExpensesChart()
                    .frame(height: 200)
            } label: {
                Label("Wydatki - ten i poprzedni miesiąc", systemImage: "chart.bar.xaxis")
            }
        }
        .padding(20)
        
    }
    
}

#Preview {
    StatisticsView()
}
