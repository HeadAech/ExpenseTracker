//
//  TagsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 05.09.2024.
//

import SwiftUI
import SwiftData

struct TagsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var tags: [Tag]
    
    @State private var showingNoTagsView: Bool = true
    
    @State private var isNewTagViewPresented: Bool = true
    
    var body: some View {
        NavigationStack {
            
            VStack {
                HStack{
                    Text("TAGS_STRING")
                        .font(.largeTitle).bold()
                    
                    Spacer()
                    
                    Button{
                        withAnimation {
                            isNewTagViewPresented.toggle()
                        }
                    } label: {
                        HStack {
                            Text("ADD_STRING")
                            Image(systemName: "plus")
                        }
                    }.buttonStyle(.bordered)
                }
                
                List{
                    
                }
                
                Spacer()
                
                
            }
            .padding(10)
            
            
            .overlay{
                if showingNoTagsView {
                    ContentUnavailableView(label: {
                        Label("NO_TAGS_STRING", systemImage: "tag.fill")
                    }, description: {
                        Text("NO_TAGS_DESCRIPTION")
                    }).animation(.easeInOut, value: showingNoTagsView)
    //                        .offset(y:15)
                }
            }
        
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        withAnimation {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                    }
                }
                
            }
        }
        
        .onAppear {
            withAnimation {
                showingNoTagsView = tags.isEmpty
            }
        }
        
        .sheet(isPresented: $isNewTagViewPresented) {
            NewTagView()
                .presentationDetents([.medium])
        }
    }
}

struct NewTagView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var icon: String = "tag"
    
    @State private var name: String = ""
    
    @State private var color: Color = .red
    
    @State private var isIconPickerPresented: Bool = false
    
    var tagToEdit: Tag?
    
    func iconPreview() -> some View {
        ZStack{
            Circle() // The shape
                .fill(color.gradient) // Background color of the shape
                .frame(width: 70, height: 70) // Adjust size of the shape
            
            Image(systemName: "tag.fill") // The image (you can use any SF Symbol or custom image)
                .resizable()
                .scaledToFit()
                .padding(20) // Add padding around the image
                .frame(width: 80, height: 80) // Adjust size of the image inside the shape
                .foregroundColor(color.foregroundColorForBackground())
        }
    }
    
    var body: some View {
        NavigationStack {
            
            VStack{
                iconPreview()
                Button{
                    
                } label: {
                    Text("CHANGE_STRING")
                }
            }.offset(y:10)
            Form{
                
                HStack{
                    Text("NAME_STRING")
                    TextField("NAME_STRING", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    ColorPicker("COLOR_STRING", selection: $color, supportsOpacity: false)
                        .multilineTextAlignment(.trailing)
                }
            }
            .scrollContentBackground(.hidden)
            
            .navigationTitle("NEW_TAG_STRING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button{
                        dismiss()
                    } label: {
                        Text("CANCEL_STRING")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button{
                        save()
                    } label: {
                        Text("SAVE_STRING")
                    }
                }
            }
        }
        
        .presentationBackground(.thinMaterial)
    }
    
    private func save() {
        
    }
}

#Preview {
    TagsView()
}
