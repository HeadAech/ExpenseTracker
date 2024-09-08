//
//  ExpensesView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 01/09/2024.
//

import SwiftUI
import SwiftData
import PhotosUI

struct LastExpensesView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse)  var expenses: [Expense]
    
    @State private var expenseToEdit: Expense?
    
    var body: some View {
        List{
//            Testing
//            LastExpenseItem(expense: Expense(name: "Wydatek", date: .now, value: 10000))
            ForEach(expenses.prefix(3)){ expense in
                LastExpenseItem(expense: expense)
                    .contextMenu{
                        Button{
                            expenseToEdit = expense
                        } label: {
                            Label("EDIT_STRING", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive){
                            withAnimation {
                                modelContext.delete(expense)
                            }
                        } label: {
                            Label("DELETE_STRING", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteItems)
            
        }
        .padding(-10)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .offset(y: -25)
        .animation(.smooth, value: expenses)
        .sheet(item: $expenseToEdit) {expense in
            NewExpenseSheet(expenseToEdit: expense)
                .presentationDetents([.medium])
        }
        
        
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}


struct LastExpenseItem: View {
    
    @State var expense: Expense
    
    var body: some View {
        
            VStack{
                HStack{
                    Text(expense.name)
                    Spacer()
                    Text(expense.value, format: .currency(code: "PLN"))
                        .font(.headline)
                        .lineLimit(1)
                      .truncationMode(.tail)
                }
                HStack{
                    Text(expense.date.formatted(date: .numeric, time: .shortened))
                        .font(.footnote)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        
    }
}


struct AllExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var filteredExpenses: [Expense] = []
    
    @State private var showingNoExpensesView: Bool = true
    
    @State private var searchText: String = ""
    
    @State private var showingSearchBar: Bool = false
    
    @FocusState private var searchBarFocused: Bool
    
    @State private var chosenExpense: Expense?
    
    func searchBar() -> some View {

        HStack{
            Image(systemName: "magnifyingglass")
            TextField("SEARCH_STRING", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { oldValue, newValue in
                    filteredExpenses = filterSearchResults(text: searchText)
                }
                .onChange(of: expenses) { oldValue, newValue in
                    filteredExpenses = filterSearchResults(text: searchText)
                }
                .focused($searchBarFocused)
            
            if !searchText.isEmpty{
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        
    }
    
    func filterSearchResults(text: String) -> [Expense] {
        if text.isEmpty{
            return expenses
        }
        
        return expenses.filter { $0.name.lowercased().contains(text.lowercased()) }
    }
    
    var body: some View {
        NavigationStack{
            
            VStack{
                HStack{
                    Text("HISTORY_STRING")
                        .font(.largeTitle).bold()
                    Spacer()
                    if !showingNoExpensesView {
                        EditButton()
                            .padding(.horizontal, 10)
                        
                        Button {
                            withAnimation{
                                showingSearchBar.toggle()
                                searchBarFocused.toggle()
                            }
                        } label: {
                            Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass.circle.fill")
                                .font(.title)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        
                    }
                }
                
                
            }
            .offset(y:0)
            .ignoresSafeArea(.keyboard)
            
            VStack{
                if showingSearchBar && !showingNoExpensesView{
                    searchBar()
                        .transition(.blurReplace)
                }
            }
            .opacity(showingSearchBar ? 1 : 0)
            .animation(.spring, value: showingSearchBar)
            
            List{
//                Test expense
//                ExpenseListItem(expense: Expense(name: "Wydatek", date: .now, value: 10000))
                
                ForEach(searchText.isEmpty ? expenses : filteredExpenses) { expense in
                    ExpenseListItem(expense: expense)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            chosenExpense = expense
                        }
                    
                }
                .onDelete(perform: deleteItems)
                
            }
            //                    .listStyle(PlainListStyle())
            .padding(.horizontal, -20)
            .scrollContentBackground(.hidden)
            
            .frame(height: UIScreen.screenHeight/2)
            .overlay {
                if showingNoExpensesView{
                    ContentUnavailableView(label: {
                        Label("NO_EXPENSES_STRING", systemImage: "dollarsign.square.fill")
                    }, description: {
                        Text("NO_EXPENSES_DESCRIPTION")
                    }).animation(.easeInOut, value: showingNoExpensesView)
                        .offset(y:15)
                }
            }
            .onChange(of: expenses.isEmpty, { oldValue, newValue in
                withAnimation{
                    showingNoExpensesView = expenses.isEmpty
                }
            })
            .onChange(of: showingSearchBar) { oldValue, newValue in
                searchText = ""
            }
            .onAppear {
                withAnimation {
                    showingNoExpensesView = expenses.isEmpty
                }
            }
            .onDisappear{
                withAnimation{
                    showingSearchBar = false
                }
            }
            
            .animation(.smooth, value: expenses)
        
        }.padding(20)
        
            .fullScreenCover(item: $chosenExpense) {expense in
                ExpenseDetailsView(expense: expense)
            }
            
    }
    
    private func refresh() {
        
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}

struct ExpenseListItem: View {
    @Environment(\.modelContext) private var modelContext
    @State var expense: Expense
    
    @State private var expenseToEdit: Expense?
    
    func iconThumbnail(color: Color, icon: String) -> some View {
        ZStack{
            Circle()
                .fill(color.gradient)
                .frame(width: 30, height: 30)
            
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(width: 40, height: 40)
                .foregroundColor(color.foregroundColorForBackground())
        }
    }
    
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                
                
                if !expense.name.isEmpty{
                    HStack{
                        
                        if expense.tag != nil {
                            
                            let tagColor: Color = Color(hex: expense.tag!.color) ?? .red
                            
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(tagColor.gradient)
                                .font(.system(size: 8))
                            
                        }
                        Text(expense.name)
                            .font(.headline)
                    }
                }
                
                HStack{
                    Text(expense.date.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                    Spacer()
                }

            }
            Spacer()
                
            Text(expense.value, format: .currency(code: "PLN"))
                .bold()
                .foregroundStyle(Color.accentColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.tail)
            

            
            
        }
        .contextMenu{
            Button{
                expenseToEdit = expense
            } label: {
                Label("EDIT_STRING", systemImage: "pencil")
            }
            
            Button(role: .destructive){
                withAnimation {
                    modelContext.delete(expense)
                }
            } label: {
                Label("DELETE_STRING", systemImage: "trash")
            }
        }

        .sheet(item: $expenseToEdit) {expense in
            NewExpenseSheet(expenseToEdit: expense)
                .presentationDetents([.medium])
        }
    }
}

struct ExpenseDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var expense: Expense
    
    @State private var isImagePreviewPresented: Bool = false
    
    @State private var isInEdit: Bool = false
    
    @State private var isDeleteAlertPresented: Bool = false
    
    func tagBox(tag: Tag) -> some View{
        let name: String = tag.name
        let color: Color = Color(hex: tag.color) ?? .secondary
        let icon: String = tag.icon
        
        return VStack{
            
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.caption)
                
                if name == "" {
                    Text("UNTAGGED_STRING")
                        .font(.caption)
                        .foregroundColor(color.foregroundColorForBackground())
                } else {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(color.foregroundColorForBackground())
                }
            }.padding(5)
            
        }.background(
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .opacity(0.8)
            )

    }
    
    var body: some View {
        
        let name = expense.name
        let date = expense.date
        let amount = expense.value
        
        VStack{
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 5)
            }
            
            HStack{
                
                Text(name)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                HStack{
                    
                    Button {
                        isInEdit.toggle()
                    } label: {
                        Image(systemName: "pencil")
                            .frame(height: 15)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(role: .destructive) {
                        isDeleteAlertPresented.toggle()
                    } label: {
                        Image(systemName: "trash.fill")
                            .frame(height: 15)
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.bordered)
                    
                }
            }
            .padding(.vertical, 10)
            
            HStack {
                if expense.tag != nil {
                    tagBox(tag: expense.tag!)
                } else {
                    tagBox(tag: Tag(name: "", color: "", icon: "tag.slash.fill"))
                }
                Spacer()
            }
            .padding(.vertical, -10)
            
            HStack {
                Text(amount, format: .currency(code: "PLN"))
                    .font(.title)
                    .bold()
                    .foregroundStyle(.tint)
                Spacer()
            }
            .padding(.vertical, 15)
            
            if expense.image != nil {
                
                Form {
                    
                    HStack{
                        
                        Button {
                            isImagePreviewPresented.toggle()
                        } label: {
                            Label {
                                Text("PHOTO_STRING")
                            } icon: {
                                Image(systemName: "photo")
                            }
                        }
                        Spacer()
                        
                        if let selectedPhotoData = expense.image, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        
                    }
                    
                }
                .padding(.horizontal, -20)
                .scrollContentBackground(.hidden)
                
            }
            
            Spacer()
            
            
            
            
            HStack {
                Text(date.formatted(date: .complete, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            .padding(.vertical, 20)
            
            
            
        }
        .padding(.horizontal, 20)
        .presentationBackground(.thinMaterial)
        
        .fullScreenCover(isPresented: $isImagePreviewPresented) {
            if let selectedPhotoData = expense.image, let image = Image(data: selectedPhotoData) {
                ImageViewer(image: image)
            }
        }
        
        .sheet(isPresented: $isInEdit) {
            NewExpenseSheet(expenseToEdit: expense)
        }
        
        .alert("DELETE_ALERT_TITLE", isPresented: $isDeleteAlertPresented) {
            Button(role: .destructive) {
                modelContext.delete(expense)
                dismiss()
            } label: {
                Text("DELETE_STRING")
            }
        }
    }
}


struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    var expenseToEdit: Expense?
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var amount: String = "0,00"
    @State private var tag: Tag?
    
    @State private var errorAlertMessage: LocalizedStringResource = "AMOUNT_LESS_THAN_ZERO_MESSAGE"
    @State private var isErrorAlertPresent: Bool = false
    
    @State private var isTagPickerPresented: Bool = false
    
    @State var selectedPhoto: PhotosPickerItem?
    @State var selectedPhotoData: Data?
    
    @FocusState var amountFocused: Bool
    
    @State private var showCameraPicker: Bool = false
    @State private var showPhotosPicker: Bool = false
    
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var midnight: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1 // The last second of the day
        return Calendar.current.date(byAdding: components, to: today) ?? today
    }
    
    var body: some View {
        NavigationStack{
            Form{
                HStack{
                    Text("NAME_STRING")
                    TextField("NAME_STRING", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                HStack{
                    //                    Label("Data", systemImage: "calendar")
                    Text("DATE_STRING")
                    DatePicker("", selection: $date, in: ...midnight)
                }
                HStack{
                    Text("AMOUNT_STRING")
                    TextField("AMOUNT_STRING", text: $amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onTapGesture {
                            
                        }
                        .onChange(of: amount) { oldValue, newValue in
                            updateAmount(from: newValue)
                        }
                        .focused($amountFocused)
                    Text("PLN")
                    
                }
                
                Section("TAG_STRING"){
                    
                    if tag != nil {
                        HStack {
                            iconThumbnail(color: Color(hex: tag!.color) ?? .red, icon: tag!.icon)
                                .padding(-10)
                            Text(tag!.name)
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                withAnimation{
                                    tag = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                    
                    HStack {
                        Button {
                            isTagPickerPresented.toggle()
                        } label: {
                            
                            Label {
                                Text("CHOOSE_TAG_STRING")
                            } icon: {
                                Image(systemName: "tag.fill")
                            }
                            
                        }
                    }

                }
                
                Section("PHOTO_STRING"){
                    
                    if let selectedPhotoData,
                       let uiImage = UIImage(data: selectedPhotoData) {
                        HStack{
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 300)
                        }
                    }
                    
                    
                    Menu{
                        //                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()){
                        //                            Label("Dodaj zdjęcie", systemImage: "photo")
                        //                        }
                        Button {
                            showPhotosPicker.toggle()
                        } label: {
                            Label("CHOOSE_PHOTO_STRING", systemImage: "photo")
                        }
                        
                        Button {
                            showCameraPicker.toggle()
                        } label: {
                            Label("TAKE_PHOTO_STRING", systemImage: "camera.fill")
                        }
                    } label: {
                        Label("ADD_PHOTO_MORE_STRING", systemImage: "photo.badge.plus.fill")
                    }
                    
                    if selectedPhotoData != nil {
                        Button(role: .destructive){
                            withAnimation{
                                selectedPhoto = nil
                                selectedPhotoData = nil
                                
                            }
                        } label: {
                            Label("DELETE_PHOTO_STRING", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                    
                }
            }
            .scrollContentBackground(.hidden)
            .onAppear {
                
                if expenseToEdit != nil {
                    name = expenseToEdit!.name
                    let parts = String(expenseToEdit!.value).split(separator: ".")
                    print(parts)
                    if parts[1].count == 1 {
                        updateAmount(from: String(expenseToEdit!.value * 10))
                    }else{
                        updateAmount(from: String(expenseToEdit!.value))
                    }
                    date = expenseToEdit!.date
                    selectedPhotoData = expenseToEdit!.image
                    
                    if expenseToEdit!.tag != nil {
                        tag = expenseToEdit!.tag
                    }
                }
                
                amountFocused.toggle()
                
            }
            .navigationTitle(expenseToEdit == nil ? "NEW_EXPENSE_STRING" : "EDIT_EXPENSE_STRING")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("CANCEL_STRING") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button(expenseToEdit != nil ? "SAVE_STRING" : "ADD_STRING") {
                        let doubleAmount = Double(amount.replacingOccurrences(of: ",", with: "."))
                        
                        if doubleAmount ?? 0 <= 0 {
                            errorAlertMessage = Error.AMOUNT_LESS_THAN_ZERO.title
                            isErrorAlertPresent.toggle()
                            return
                        }
                        if date > Date() {
                            errorAlertMessage = Error.DATE_FROM_THE_FUTURE.title
                            isErrorAlertPresent.toggle()
                            return
                        }
                        
                        if expenseToEdit != nil {
                            expenseToEdit!.name = name
                            expenseToEdit!.date = date
                            expenseToEdit!.value = doubleAmount ?? 0
                            if selectedPhotoData != nil {
                                expenseToEdit!.image = selectedPhotoData
                            }
                            if tag != nil {
                                expenseToEdit!.tag = tag
                            }
                            withAnimation{
//                                modelContext.insert(expenseToEdit!)
                                dismiss()
                            }
                        } else {
                            
                            let expense = Expense(name: name, date: date, value: doubleAmount ?? 0)
                            if tag != nil {
                                expense.tag = tag!
                            }
                            if selectedPhotoData != nil {
                                expense.image = selectedPhotoData
                            }
                            withAnimation{
                                modelContext.insert(expense)
                                dismiss()
                            }
                        }
                        
                        
                    }
                    .alert(Text(errorAlertMessage), isPresented: $isErrorAlertPresent){
                        Button("OK", role: .cancel) { }
                    }
                    
                }
                
            }
            
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
            .task(id: selectedPhoto){
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self){
                    selectedPhotoData = data
                }
            }
            
        }
        .presentationBackground(.thinMaterial)
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView() { image in
                selectedPhotoData = image.jpegData(compressionQuality: 0.8)
            }
        }
        
        .fullScreenCover(isPresented: $isTagPickerPresented) {
            TagPickerView(selectedTag: $tag)
        }
        
        
        
    }
    
    func iconThumbnail(color: Color, icon: String) -> some View {
        ZStack{
            Circle()
                .fill(color.gradient)
                .foregroundStyle(color.gradient)
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.palette)
            
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .padding(20)
                .frame(width: 65, height: 65)
                .foregroundColor(color.foregroundColorForBackground())
                .foregroundStyle(color.gradient)
        }
    }
    
    // Updates the amount by building up from the input string
    private func updateAmount(from newValue: String) {
        // Allow only digits
        let filtered = newValue.filter { "0123456789".contains($0) }
        
        
        if let numericValue = Int(filtered) {
            // Update amount as an integer to shift the decimal place
            amount = String(numericValue)
            amount = formattedAmount()
        } else {
            amount = "0,00"
        }
    }
    
    // Converts the current amount to a formatted string with 2 decimal places
    private func formattedAmount() -> String {
        if let value = Double(amount) {
            return String(format: "%.2f", value / 100).replacingOccurrences(of: ".", with: ",")
            
        }
        return "0,00"
    }
    
}


#Preview {
    @Previewable @State var expense: Expense = Expense(name: "Test expense", date: .now, value: 200.96)
    
    ExpenseDetailsView(expense: expense)
}
