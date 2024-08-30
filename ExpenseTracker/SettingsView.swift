//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    
//    @State private var isSummingDaily: Bool = true
    @AppStorage("settings:isSummingDaily") private var isSummingDaily: Bool = true
    
    enum Summing: String, CaseIterable, Identifiable {
        case daily, monthly
        
        var id: Self { self }
    }
    
    @State private var selectedSumming: Summing = .daily
    
    var body: some View {
        NavigationStack{
            Form{
                Picker("Sumowanie", selection: $selectedSumming) {
                    Text("Codzienne").tag(Summing.daily)
                    Text("Miesięczne").tag(Summing.monthly)
                }.onChange(of: selectedSumming, initial: false){
                    isSummingDaily = selectedSumming == .daily ? true : false
                    UserDefaults.standard.set(isSummingDaily, forKey: "settings:isSummingDaily")
                }
                .onAppear {
                    selectedSumming = isSummingDaily ? .daily : .monthly
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
