//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                Picker("Suma wydatków", selection: $selectedSumming) {
                    Text("Dzisiaj").tag(Summing.daily)
                    Text("Ten miesiąc").tag(Summing.monthly)
                }.onChange(of: selectedSumming, initial: false){
                    isSummingDaily = selectedSumming == .daily ? true : false
                    UserDefaults.standard.set(isSummingDaily, forKey: "settings:isSummingDaily")
                }
                .onAppear {
                    selectedSumming = isSummingDaily ? .daily : .monthly
                }
            }
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("Gotowe") {
                        dismiss()
                    }
                }

            }
        }
    }
}

#Preview {
    SettingsView()
}
