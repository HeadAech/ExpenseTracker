//
//  IconPickerView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 05.09.2024.
//

import SwiftUI

struct IconPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var chosenIcon: String
    
    let gridItem: GridItem = GridItem(.flexible())
    
    @State private var searchText: String = ""
    
    @State private var icons: [Icon] = Icon.allCases
    
    var filteredIcons: [Icon] {
        if searchText.isEmpty {
            return Icon.allCases
        }
        
        return icons.filter {$0.rawValue.lowercased().contains(searchText.lowercased())}
    }
    
    var body: some View {
        NavigationStack {
            
            let columns: [GridItem] = [gridItem, gridItem, gridItem, gridItem]
            
            VStack{
                ScrollView{
                    LazyVGrid(columns: columns) {
                        
                        ForEach(filteredIcons, id: \.self) {icon in
                            
                            iconView(name: icon.rawValue)
                            
                        }
                        
                    }
                    
                }
                Spacer()
                
            }.padding(15)
            
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("CANCEL_STRING")
                        }

                    }
                }
        }
        .searchable(text: $searchText)
        .presentationBackground(.thinMaterial)
        
    }

    
    func iconView(name: String) -> some View {
        ZStack{
            RoundedRectangle(cornerRadius: 5)
                .frame(width:70, height: 70)
                .background(.thickMaterial)
                .opacity(name == chosenIcon ? 0.5 : 0.13)
            Button {
                chosenIcon = name
                dismiss()
            } label: {
                Image(systemName: name)
                    .font(.system(size: 34))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    
            }
            .buttonStyle(.plain)
            .frame(width: 80, height: 80)
            
        }
    }
}

#Preview {
    @Previewable @State var icon: String = "tag.fill"
    IconPickerView(chosenIcon: $icon)
}
