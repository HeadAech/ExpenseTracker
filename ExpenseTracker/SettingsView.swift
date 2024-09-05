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
    @AppStorage("settings:gradientColorIndex") private var gradientColorIndex: Int = 0
    
    private var gradientColors: [Int: Color] = Colors().gradientColors
    
    enum Summing: String, CaseIterable, Identifiable {
        case daily, monthly
        
        var id: Self { self }
    }
    
    @State private var selectedSumming: Summing = .daily
    @State private var selectedGradientColor: Int = 0
    
    var body: some View {
        NavigationStack{
            Form{
                Picker("TOTAL_EXPENSES_STRING", selection: $selectedSumming) {
                    Text("TODAY_STRING").tag(Summing.daily)
                    Text("THIS_MONTH_STRING").tag(Summing.monthly)
                }.onChange(of: selectedSumming, initial: false){
                    isSummingDaily = selectedSumming == .daily ? true : false
                    UserDefaults.standard.set(isSummingDaily, forKey: "settings:isSummingDaily")
                }
                .onAppear {
                    selectedSumming = isSummingDaily ? .daily : .monthly
                }
                
                Section("THEME_STRING"){
                    Picker("GRADIENT_COLOR_STRING", selection: $selectedGradientColor) {
                        ForEach(gradientColors.sorted(by: { $0.key < $1.key }), id: \.key){ key, value in
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(value)
                        }
                    }.pickerStyle(.palette)
                        .onChange(of: selectedGradientColor, initial: false) {
                            UserDefaults.standard.set(selectedGradientColor, forKey: "settings:gradientColorIndex")
                        }
                        .onAppear{
                            selectedGradientColor = gradientColorIndex
                        }

                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("SETTINGS_STRING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("DONE_STRING") {
                        dismiss()
                    }
                }

            }
            .tint(Colors().getColor(for: gradientColorIndex))
            .animation(.easeInOut, value: gradientColorIndex)
        }
    }
}

#Preview {
    SettingsView()
}
