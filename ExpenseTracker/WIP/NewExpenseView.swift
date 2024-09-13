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
            ScrollView{
                VStack {
                    
                    expenseDetails
                        .padding(.top, 15)
                    
                    
                    
//                    Button {
//                        
//                    } label: {
//                        Label("TOGGLE_NUMPAD_STRING", systemImage: "keyboard.badge.eye")
//                    }.padding(.top, 10)
//                        .buttonStyle(.bordered)
                    
                    numericPad
                        .padding(.top, 20)
                    
                    Spacer()
                    
                }
            }
            
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
            HStack{
                
                photoButton
                
                Spacer()
                
                amountView
                    .onChange(of: amountString) { oldValue, newValue in
                        updateAmount(from: newValue)
                    }
                
                Spacer()
                
                tagButton
                
            }.padding(.horizontal, 20)
            
            HStack(alignment: .center){
                Form{
                    TextField("NAME_STRING", text: $name, prompt: Text("NAME_STRING"))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .onChange(of: name) { oldValue, newValue in
                            limitCharacters(text: oldValue, maxLength: 30)
                        }
                    
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .padding(.top, -15)
                .frame(height: 70)
            }
            
            HStack(alignment: .center){
                Spacer()
                DatePicker("", selection: $date, in: ...midnight)
                    .labelsHidden()
                Spacer()
            }
            .padding(5)
            
        }
    }
    
    private var tagButton: some View {
        Button {
            isTagPickerPresented.toggle()
        } label: {
            if tag != nil {
                Image(systemName: tag!.icon)
                    .font(.title2)
                    .padding(5)
            } else {
                Image(systemName: "tag.fill")
                    .font(.title2)
                    .padding(5)
            }
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        
    }
    
    
    private var photoButton: some View {
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
            Image(systemName: selectedPhotoData == nil ? "photo.badge.plus" : "photo.badge.checkmark")
                .font(.title2)
                .padding(5)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
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
