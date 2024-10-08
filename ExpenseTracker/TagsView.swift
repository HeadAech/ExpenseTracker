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
    
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @Query private var expenses: [Expense]
    
    @State private var showingNoTagsView: Bool = true
    
    @State private var isNewTagViewPresented: Bool = false
    
    @State private var tagToEdit: Tag?
    
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
        .padding(10)
    }
    
    var body: some View {
        NavigationStack {
  
            VStack {
                HStack {
                    Spacer()
                    
                    closeButton
                    
                }
                
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
                .padding()
                
                List{
//                    Test
//                    tagItem(tag: Tag(name: "Test", color: "#ff0000", icon: "tag.fill"))
                    ForEach(tags) {tag in
                        
                        tagItem(tag: tag)
                    }
                }
                .scrollContentBackground(.hidden)
                .padding(-10)
                
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

        }
        
        .onAppear {
            withAnimation {
                showingNoTagsView = tags.isEmpty
            }
        }
        
        .onChange(of: tags, { oldV, newV in
            withAnimation {
                showingNoTagsView = tags.isEmpty
            }
        })

        .sheet(isPresented: $isNewTagViewPresented) {
            NewTagView()
        }
        
        .sheet(item: $tagToEdit) {tag in
            NewTagView(tagToEdit: tag)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                nullifyExpensesTags(tag: tags[index])
                modelContext.delete(tags[index])
            }
        }
    }
    
    func nullifyExpensesTags(tag: Tag) {
        for expense in expenses{
            if expense.tag == tag {
                expense.tag = nil
            }
        }
    }
    
    func tagItem(tag: Tag) -> some View{
        
        VStack{
            
            let name: String = tag.name
            let color: Color = Color(hex: tag.color) ?? .red
            let icon: String = tag.icon
            
            HStack{
                iconThumbnail(color: color, icon: icon)
                    .padding(.horizontal, -5)
                Text(name)
                    .font(.headline)
            }
        }.padding(-10)
            .contextMenu {
                Button{
                    tagToEdit = tag
                } label: {
                    Label {
                        Text("EDIT_STRING")
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
                
                Button(role: .destructive) {
                    nullifyExpensesTags(tag: tag)
                    withAnimation{
                        modelContext.delete(tag)
                    }
                } label: {
                    Label {
                        Text("DELETE_STRING")
                    } icon: {
                        Image(systemName: "trash.fill")
                    }
                }
            }
    }
    
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
        }
    }
}

struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query private var expenses: [Expense]
    
    @State private var showingNoTagsView: Bool = true
    
    @State private var isNewTagViewPresented: Bool = false
    
    @State private var tagToEdit: Tag?
    
    @Binding var selectedTag: Tag?
    
    @State private var searchText: String = ""
    
    @AppStorage("settings:selectingTagDismisses") private var selectingTagDismissesSetting: Bool = true
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText.localizedLowercase) }
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
//        .padding(10)
    }
    
    private var addTagButton: some View {
        Button{
            withAnimation {
                isNewTagViewPresented.toggle()
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
    
    
    var body: some View {
        NavigationStack {
            
            VStack {
                
                List{
//                    Test
//                    tagItem(tag: Tag(name: "Test", color: "#ff0000", icon: "tag.fill"))
                    ForEach(searchText.isEmpty ? tags : filteredTags) {tag in
                        
                        HStack{
                            tagItem(tag: tag)
                                
                            Spacer()
                            HStack{
                                if selectedTag == tag {
                                    Text(Image(systemName: "checkmark"))
                                        .font(.title)
                                        .foregroundStyle(.tint)
                                        .transition(.scale)
                                }
                            }
                            .opacity(selectedTag == tag ? 1 : 0)
                            .animation(.spring, value: selectedTag)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation{
                                if selectedTag == tag {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tag
                                    if selectingTagDismissesSetting {
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .automatic)
                .scrollContentBackground(.hidden)
                .padding(-10)

                
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
            
            
            .navigationTitle("TAGS_STRING")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addTagButton
                }
                
            }
            
        }
        
        .onAppear {
            withAnimation {
                showingNoTagsView = tags.isEmpty
            }
        }
        
        .onChange(of: tags, { oldV, newV in
            withAnimation {
                showingNoTagsView = tags.isEmpty
            }
        })
//        .presentationBackground(.thinMaterial)
        
        .sheet(isPresented: $isNewTagViewPresented) {
            NewTagView()
        }
        
        .sheet(item: $tagToEdit) {tag in
            NewTagView(tagToEdit: tag)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                nullifyExpensesTags(tag: tags[index])
                modelContext.delete(tags[index])
            }
        }
    }
    
    func nullifyExpensesTags(tag: Tag) {

        for expense in expenses{
            if expense.tag == tag {
                expense.tag = nil
            }
        }
    }
    
    func tagItem(tag: Tag) -> some View{
        
        VStack{
            
            let name: String = tag.name
            let color: Color = Color(hex: tag.color) ?? .red
            let icon: String = tag.icon
            
            HStack{
                iconThumbnail(color: color, icon: icon)
                    .padding(.horizontal, -5)
                Text(name)
                    .font(.headline)
            }
        }.padding(-10)
            .contextMenu {
                Button{
                    tagToEdit = tag
                } label: {
                    Label {
                        Text("EDIT_STRING")
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
                
                Button(role: .destructive) {
                    withAnimation{
                        nullifyExpensesTags(tag: tag)
                        modelContext.delete(tag)
                    }
                } label: {
                    Label {
                        Text("DELETE_STRING")
                    } icon: {
                        Image(systemName: "trash.fill")
                    }
                }
            }
    }
    
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
        }
    }
}

struct NewTagView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var icon: String = "tag.fill"
    
    @State private var name: String = ""
    
    @State private var color: Color = .red
    
    @State private var isIconPickerPresented: Bool = false
    
    var tagToEdit: Tag?
    
    func iconPreview() -> some View {
        ZStack{
            Circle()
                .fill(color.gradient)
                .frame(width: 70, height: 70)
            
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(20) 
                .frame(width: 80, height: 80)
                .foregroundColor(color.foregroundColorForBackground())
        }
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding()
    }
    
    private var saveButton: some View {
        Button {
//            Save logic
            save()
        } label: {
            Image(systemName: "checkmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding()
    }
    
    var body: some View {
        NavigationStack {
            
            VStack{
                iconPreview()
                    .onTapGesture {
                        isIconPickerPresented.toggle()
                    }
                Button{
                    isIconPickerPresented.toggle()
                } label: {
                    Text("CHANGE_ICON_STRING")
                }
            }.offset(y:10)
            Form{
                
                HStack{
                    Text("NAME_STRING")
                    TextField("NAME_STRING", text: $name)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: name) { old, new in
                            limitCharacters(text: old, maxLength: 25)
                        }
                }
                
                HStack {
                    ColorPicker("COLOR_STRING", selection: $color, supportsOpacity: false)
                        .multilineTextAlignment(.trailing)
                }
            }
            .scrollContentBackground(.hidden)
            
            .navigationTitle(tagToEdit != nil ? "EDIT_TAG_STRING" : "NEW_TAG_STRING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
        }
        .onAppear {
            if tagToEdit != nil {
                name = tagToEdit!.name
                color = Color(hex: tagToEdit!.color) ?? .red
                icon = tagToEdit!.icon
            }
        }
        .sheet(isPresented: $isIconPickerPresented) {
            IconPickerView(chosenIcon: $icon)
        }
        
        .presentationDetents([.medium])
//        .presentationBackground(.thinMaterial)
    }
    
    private func limitCharacters(text: String, maxLength: Int) {
        if name.count > maxLength {
            name = text
        }
    }
    
    private func save() {
        if name.isEmpty { return }
        
        if tagToEdit != nil {
            tagToEdit!.name = name
            tagToEdit!.color = color.toHex() ?? "#fc0000"
            tagToEdit!.icon = icon
            dismiss()
            return
        }
        
        let newTag = Tag(name: name, color: color.toHex() ?? "#fc0000", icon: icon)
        
        modelContext.insert(newTag)
        dismiss()
    }
}

#Preview {
    @Previewable @State var selectedTag: Tag?
    TagPickerView(selectedTag: $selectedTag)
        .modelContainer(for: Expense.self, inMemory: true)
        .modelContainer(for: Tag.self, inMemory: true)
}
