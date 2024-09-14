//
//  NewExpenseView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 13.09.2024.
//

import SwiftUI
import SwiftData
import PhotosUI

struct NewExpenseView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var expenseToEdit: Expense?
    
    
    @FocusState private var amountFocused: Bool
    
//    covers variables
    @State private var showCameraPicker: Bool = false
    @State private var isTagPickerPresented: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var isImagePreviewPresented: Bool = false
    
    @State private var errorAlertMessage: LocalizedStringResource = "AMOUNT_LESS_THAN_ZERO_MESSAGE"
    @State private var isErrorAlertPresent: Bool = false
    
//    expense variables
    @State private var name: String = ""
    
    @State private var amountString: String = "0.00"
    @State private var amount: Double = 0.00
    
    @State private var date: Date = .now
    
    @State var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    
    @State private var tag: Tag?

    var body: some View {
        NavigationStack {
//            ScrollView{
                VStack {
                    
                    expenseDetails
                        .padding(.top, 15)
                    
                    
                    
//                    Button {
//                        
//                    } label: {
//                        Label("TOGGLE_NUMPAD_STRING", systemImage: "keyboard.badge.eye")
//                    }.padding(.top, 10)
//                        .buttonStyle(.bordered)
                    
//                    numericPad
//                        .padding(.top, 20)
                    
                    Spacer()
                    
                }
//            }
            
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
                
            }
            .onAppear {
                
                if expenseToEdit != nil {
                    name = expenseToEdit!.name
                    let parts = String(expenseToEdit!.value).split(separator: ".")
                    
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
                
            }
            .navigationTitle(expenseToEdit == nil ? "NEW_EXPENSE_STRING" : "EDIT_EXPENSE_STRING")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationBackground(.thinMaterial)
        .alert(Text(errorAlertMessage), isPresented: $isErrorAlertPresent){
            Button("OK", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .task(id: selectedPhoto){
            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self){
                selectedPhotoData = data
            }
        }
        
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView() { image in
                selectedPhotoData = image.jpeg(.low)
            }
        }
        
        .fullScreenCover(isPresented: $isTagPickerPresented) {
            TagPickerView(selectedTag: $tag)
        }
        
        
        .fullScreenCover(isPresented: $isImagePreviewPresented) {
            if selectedPhotoData != nil, let image = Image(data: selectedPhotoData!) {
                ImageViewer(image: image)
            }
        }
        
    }
    
    private var numericPad: some View {
        VStack {
            let columns = [GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80))]
            LazyVGrid(columns: columns, spacing: 2) {
                numericPadButton(number: "1")
                numericPadButton(number: "2")
                numericPadButton(number: "3")
            }
            LazyVGrid(columns: columns, spacing: 2)  {
                numericPadButton(number: "4")
                numericPadButton(number: "5")
                numericPadButton(number: "6")
            }
            LazyVGrid(columns: columns, spacing: 2) {
                numericPadButton(number: "7")
                numericPadButton(number: "8")
                numericPadButton(number: "9")
            }
            LazyVGrid(columns: columns, spacing: 2) {
                Spacer()
                numericPadButton(number: "0")
                backspaceButton
            }
        }.sensoryFeedback(.increase, trigger: amount)
    }
    
    private func numericPadButton(number: String) -> some View {
        Button {
            amountString += number
        } label: {
            Text(number)
                .font(.title)
                .bold()
                .padding(15)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
    
    private var backspaceButton: some View {
        Button {
            amountString.removeLast()
        } label: {
            Image(systemName: "delete.backward.fill")
                .font(.title2)
                .bold()
                .padding(15)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
    
    private var expenseDetails: some View {
        
        VStack{
            
            TextField("", text: $amountString).opacity(0).frame(height: 0).focused($amountFocused)
            
            HStack{
                
//                photoButton
                dateButton
                    .popover(isPresented: $datePopoverPresented, arrowEdge: .top) {
                        DatePicker("", selection: $date, in: ...midnight)
                            .datePickerStyle(.graphical)
                            .frame(minWidth: 300)
//                        Text("Hi")
                            .presentationCompactAdaptation(.popover)
                    }
                
                Spacer()
                
                
                amountView
                    .onChange(of: amountString) { oldValue, newValue in
                        updateAmount(from: newValue)
                    }
                    .onTapGesture {
                        withAnimation{
                            amountFocused = true
                        }
                    }
                    .onAppear {
                        withAnimation {
                            amountFocused = true
                        }
                        
                    }
                    
                
//                Spacer()
                
//                tagButton
                
            }.padding(.horizontal, 20)
            
            Form{
                HStack{
                    Text("NAME_STRING")
                    
                    Spacer()
                    
                    TextField("NAME_STRING", text: $name, prompt: Text("NAME_STRING"))
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .onChange(of: name) { oldValue, newValue in
                            limitCharacters(text: oldValue, maxLength: 25)
                        }
                    
                }
                
                Section("TAG_STRING") {
                    
                    HStack {
                        tagButton
                    }.contentShape(Rectangle())
                    
                }
                
                Section("PHOTO_STRING") {
                    
                    HStack {
                        photoButton
                    }.contentShape(Rectangle())
                    
                }
                
            }
            .scrollContentBackground(.hidden)
            .padding(.top, -15)
            
            
        }
    }
    
    @State private var datePopoverPresented: Bool = false
    
    private var dateButton: some View {
        Button {
            datePopoverPresented.toggle()
        } label: {
            Image(systemName: "calendar.badge.clock")
                .font(.title)
                .padding(5)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
    
    private var tagButton: some View {
        Button {
            isTagPickerPresented.toggle()
        } label: {
            HStack {
                
                if tag == nil {
                    Label("CHOOSE_TAG_STRING", systemImage: "tag.fill")
                        .padding(.vertical, 10)
                } else {
                    HStack {
                        
                        iconThumbnail(color: Color(hex: tag!.color) ?? .red, icon: tag!.icon)
                        
                        Text(tag!.name)
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, 5)
                        
                        
                        
                    }.padding(.vertical, 5)
                }
                Spacer()
                
                Image(systemName: "chevron.forward")
                
                if tag != nil {
                    clearTagButton
                        .padding(.trailing, -5)
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
        }.padding(-10)
    }
    
    private var photoButton: some View {
        HStack {
            Menu{
                if selectedPhotoData != nil {
                    Button{
                        isImagePreviewPresented.toggle()
                    } label: {
                        Label("PREVIEW_STRING", systemImage: "eye")
                    }
                    
                    Button(role: .destructive){
                        withAnimation{
                            selectedPhoto = nil
                            selectedPhotoData = nil
                            
                        }
                    } label: {
                        Label("DELETE_PHOTO_STRING", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    
                    Divider()
                }
                
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
                HStack{
                    if selectedPhotoData == nil {
                        Label("ADD_PHOTO_MORE_STRING", systemImage: "photo.badge.plus")
                    } else {
                        HStack {
                            if let uiImage = UIImage(data: selectedPhotoData!) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                    .padding(.vertical, -5)
                            }
                            
                            Text("PHOTO_STRING")
                                .padding(.leading, 5)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    
                    
                    Spacer()
                    
                    Image(systemName: "ellipsis.circle.fill")
                    
                    
                }
                .padding(.vertical, 10)
            }
            
            if selectedPhotoData != nil {
                clearPhotoButton
                    .zIndex(10)
                    .padding(.trailing, -5)
            }
            
        }
    }
    
    private var amountView: some View {
        
        Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            .font(.largeTitle)
            .bold()
            .contentTransition(.numericText())
            .animation(.smooth(), value: amount)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .truncationMode(.tail)
//            .underlineTextField(color: .accentColor, isActive: amountFocused)
            .foregroundStyle(amountFocused ? Color.accentColor : Color.primary)
            .animation(.spring(duration: 0.2), value: amountFocused)
        
    }
    
    private var clearTagButton: some View {
        Button(role: .destructive) {
            withAnimation {
                tag = nil
            }
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(Color.red)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
    
    private var clearPhotoButton: some View {
        Button(role: .destructive) {
            withAnimation {
                selectedPhoto = nil
                selectedPhotoData = nil
            }
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(Color.red)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
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
    
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var midnight: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1 // The last second of the day
        return Calendar.current.date(byAdding: components, to: today) ?? today
    }
    
//    Functions
    
    private func updateAmount(from newValue: String) {
        // Allow only digits
        let filtered = newValue.filter { "0123456789".contains($0) }
        
        
        if let numericValue = Int(filtered) {
            // Update amount as an integer to shift the decimal place
            amountString = String(numericValue)
        } else {
            amountString = "0.00"
        }
        
        amount = (Double(amountString) ?? 0.0) / 100
    }
    
    private func limitCharacters(text: String, maxLength: Int) {
        if name.count > maxLength {
            name = text
        }
    }
    
    private func save() {
//        let doubleAmount = Double(amount.replacingOccurrences(of: ",", with: "."))
        
        if amount <= 0 {
            errorAlertMessage = Error.AMOUNT_LESS_THAN_ZERO.title
            isErrorAlertPresent.toggle()
            return
        }
        
        if date > Date() {
            errorAlertMessage = Error.DATE_FROM_THE_FUTURE.title
            isErrorAlertPresent.toggle()
            return
        }
        
        if name.isEmpty {
            errorAlertMessage = Error.NAME_IS_EMPTY.title
            isErrorAlertPresent.toggle()
            return
        }
        
        if expenseToEdit != nil {
            expenseToEdit!.name = name
            expenseToEdit!.date = date
            expenseToEdit!.value = amount
            expenseToEdit!.image = selectedPhotoData
            expenseToEdit!.tag = tag
            
            withAnimation{
//                                modelContext.insert(expenseToEdit!)
                dismiss()
            }
        } else {
            
            let expense = Expense(name: name, date: date, value: amount)
            if tag != nil {
                expense.tag = tag!
            }
            if selectedPhotoData != nil {
                expense.image = UIImage(data: selectedPhotoData!)!.jpeg(.low)
            }
            withAnimation{
                modelContext.insert(expense)
                dismiss()
            }
        }
        
    }
    
}



#Preview {
    NewExpenseView()
}
