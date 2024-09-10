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
        
        return icons.filter {
            String(localized: $0.localized).lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            
            let columns: [GridItem] = [gridItem, gridItem, gridItem, gridItem]
            
            VStack{
                ScrollView{
                    LazyVGrid(columns: columns) {
                        
                        ForEach(filteredIcons.sorted(by: {String(localized: $0.localized).lowercased() < String(localized: $1.localized).lowercased()}), id: \.self) {icon in
                            
                            iconView(icon: icon)
                            
                        }
                        
                    }
                    
                }
                Spacer()
                
            }.padding(15)
            
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        closeButton
                    }
                }
        }
        .searchable(text: $searchText)
        .presentationBackground(.thinMaterial)
        
    }
    private var closeButton: some View {
        Button {
            withAnimation {
                dismiss()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding(.vertical, 5)
    }
    
    func iconView(icon: Icon) -> some View {
        VStack {
            let name = icon.rawValue
            
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
            Text(icon.localized)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .truncationMode(.tail)
                .lineLimit(1)
        }
    }
}

#Preview {
    @Previewable @State var icon: String = "tag.fill"
    IconPickerView(chosenIcon: $icon)
}
