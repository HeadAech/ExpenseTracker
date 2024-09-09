//
//  PinPadView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 09.09.2024.
//

import SwiftUI
import LocalAuthentication

public enum PinAction {
    case SAVE, DELETE, CONFIRM, DISABLE
    
    var id: Self {self}
}

private enum Prompt{
    case CONFIRM, NEW_PIN, ENTER_PIN
    
    var title: LocalizedStringResource {
        switch self {
            
        case .CONFIRM: "CONFIRM_PIN_STRING"
        case .NEW_PIN: "NEW_PIN_STRING"
        case .ENTER_PIN: "ENTER_PIN_STRING"
        }
    }
}

struct PinPadView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var prompt: Prompt = .ENTER_PIN
    
    @State private var pin: String = ""
    
//    @Binding var pinToReturn: String
    var canDismiss: Bool = true
    
    var useBiometrics: Bool = false
    
    @Binding var pinAction: PinAction
    
    @State private var wrongPin: Bool = false
    
    @State private var deletionConfirmed: Bool = false
    @State private var pinToSave: String = ""
    
    func pinPadButton(number: String) -> some View {
        Button {
            pin += number
        } label: {
            Text(number)
                .padding(20)
                .font(.title)
        }.buttonStyle(.bordered)
            .clipShape(Circle())
    }
    
    func eraseButton() -> some View {
        Button {
            if !pin.isEmpty{
                pin.removeLast()
            }
        } label: {
            Image(systemName: "delete.backward")
                .padding(20)
                .font(.title)
        }.buttonStyle(.bordered)
            .clipShape(Circle())
            
    }
    
    func pinPad() -> some View {
        
        VStack {
            
            HStack {
                
                pinPadButton(number: "1")
                
                pinPadButton(number: "2")
                
                pinPadButton(number: "3")
            }
            
            HStack {
                pinPadButton(number: "4")
                
                pinPadButton(number: "5")
                
                pinPadButton(number: "6")
            }
            
            HStack {
                pinPadButton(number: "7")
                
                pinPadButton(number: "8")
                
                pinPadButton(number: "9")
            }
            
            HStack {
                Spacer()
                
                pinPadButton(number: "0")
                
                Spacer()
            }
            
        }.font(.title)
        
    }
    
    var body: some View {
        VStack {
            
            
            HStack{
                if useBiometrics {
                    Button {
                        if useBiometrics {
                            authenticate()
                        }
                    } label: {
                        Image(systemName: "faceid")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                    .padding()
                }
                
                Spacer()
                
                if canDismiss {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                    .padding()
                }
                
            }.padding(.horizontal, 10)
            
            
            Spacer()
            
            Text(prompt.title)
                .font(.title)
                .contentTransition(.numericText())
                .animation(.smooth, value: prompt)

            
            HStack(alignment: .center) {
                
                HStack {
                    Image(systemName: pin.count > 0 ? "circle.fill" : "circle")
                    Image(systemName: pin.count > 1 ? "circle.fill" : "circle")
                    Image(systemName: pin.count > 2 ? "circle.fill" : "circle")
                    Image(systemName: pin.count > 3 ? "circle.fill" : "circle")
                }
                .symbolEffect(.bounce, value: wrongPin)
                    .lineLimit(1)
                    .onChange(of: pin) { oldValue, newValue in
                        if pin.count > 4 {
                            pin = oldValue
                        } else {
                            pin = newValue
                        }
                        
                        if pin.count == 4 {
                            if pinAction == .DISABLE{
                                if !confirmPin() {
                                    withAnimation{
                                        wrongPin.toggle()
                                        pin = ""
                                    }
                                } else {
                                    UserDefaults.standard.set(false, forKey: "settings:lockAccess")
                                    UserDefaults.standard.set(false, forKey: "settings:useFaceID")
                                    UserDefaults.standard.set(false, forKey: "settings:settingsAuthenticated")
                                    deletePin()
                                    dismiss()
                                }
                            }
                            
                            if pinAction == .CONFIRM{
                                if !confirmPin() {
                                    withAnimation{
                                        wrongPin.toggle()
                                        pin = ""
                                    }
                                } else {
                                    dismiss()
                                }
                            }
                            
                            if pinAction == .SAVE {
                                if pinToSave.isEmpty {
                                    pinToSave = pin
                                    pin = ""
                                    prompt = .CONFIRM
                                } else {
                                    if pinToSave == pin {
                                        savePin()
                                        dismiss()
                                    } else {
                                        withAnimation {
                                            wrongPin.toggle()
                                            pin = ""
                                        }
                                    }
                                }
                            }
                            
                            if pinAction == .DELETE {
                                if !confirmPin() {
                                    withAnimation{
                                        wrongPin.toggle()
                                        pin = ""
                                    }
                                } else {
                                    deletePin()
                                    dismiss()
                                }
                            }
                        }
                    }
                    .frame(width: 100, height: 50)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: pin)
                    .disabled(true)
                
            }
            
            Spacer()
            
            pinPad()
                
            
            Spacer()
            
            HStack{
                Spacer()
                
                eraseButton()
                    .opacity(pin.count > 0 ? 1 : 0)
                    .animation(.easeInOut, value: pin)
                
                Spacer()
                
                
            }
            Spacer()
        }
        .onAppear {
            print(pinAction)
            
            if pinAction == .DELETE {
                prompt = .ENTER_PIN
            }
            
            if pinAction == .SAVE {
                prompt = .NEW_PIN
            }
            
            if pinAction == .CONFIRM {
                prompt = .ENTER_PIN
            }
            
            if pinAction == .DISABLE {
                prompt = .ENTER_PIN
            }
            
            if useBiometrics {
                authenticate()
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    pin = getPin()
                } else {
                    pin = ""
                }
            }
        } else {
            pin = ""
        }
    }
    
    func getPin() -> String {
        let keychain: KeychainWrapper = KeychainWrapper()
        
        if let pin = keychain.getPin() {
            return pin
        } else {
            return "____"
        }
    }
    
    func confirmPin() -> Bool {
        let keychain: KeychainWrapper = KeychainWrapper()
        
        return keychain.getPin() == pin
    }
    
    private func savePin() {
        let keychain: KeychainWrapper = KeychainWrapper()
        
        keychain.addPin(pin: pin)
        UserDefaults.standard.set(true, forKey: "settings:lockAccess")
    }
    

     private func deletePin() {
         
         let keychain: KeychainWrapper = KeychainWrapper()
         
         keychain.deletePin()
         
         UserDefaults.standard.set(false, forKey: "settings:lockAccess")
     }
}

#Preview {
    @Previewable @State var pinAction: PinAction = .CONFIRM
    
    PinPadView(pinAction: $pinAction)
}
