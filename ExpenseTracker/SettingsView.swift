//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData
import LocalAuthentication



struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
//    @State private var isSummingDaily: Bool = true
    
//    Settings values
    @AppStorage("settings:isSummingDaily") private var isSummingDaily: Bool = true
    @AppStorage("settings:gradientColorIndex") private var gradientColorIndex: Int = 0
    
    @AppStorage("settings:lockAccess") private var lockAccess: Bool = false
    @AppStorage("settings:useFaceID") private var useFaceID: Bool = false
    @AppStorage("settings:settingsAuthenticated") private var settingsAuthenticated: Bool = false
    
    private var gradientColors: [Int: Color] = Colors().gradientColors
    
    enum Summing: String, CaseIterable, Identifiable {
        case daily, monthly
        
        var id: Self { self }
    }
    
    @State private var selectedSumming: Summing = .daily
    @State private var selectedGradientColor: Int = 0
    
    @State private var isLockingAccess: Bool = false
    @State private var isPinPadPresented: Bool = false
    
    @State private var pinAction: PinAction = .CONFIRM
    
    @State private var isUsingFaceID: Bool = false
    
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
                
                
                Section("PRIVACY_STRING") {
                    Toggle(isOn: $isLockingAccess) {
                        Label {
                            Text("LOCK_DATA_STRING")
                        } icon: {
                            Image(systemName: "lock.fill")
                        }
                    }
                    .onChange(of: isLockingAccess, { oldValue, newValue in
//                        UserDefaults.standard.set(newValue, forKey: "settings:lockAccess")
                        if isLockingAccess == true {
                            handlePin()
                        }
                        
                        if isLockingAccess == false {
                            pinAction = .DISABLE
                            isPinPadPresented.toggle()
                        }
                    })
                    .onAppear {
                        isLockingAccess = lockAccess
                    }
                    
                    if isLockingAccess {
                        
//                        Button(role: .destructive) {
//                            deletePin()
//                        } label: {
//                            Label {
//                                Text("DELETE_PIN_STRING")
//                            } icon: {
//                                Image(systemName: "trash.fill")
//                            }.foregroundStyle(.red)
//                        }
                        
                        Toggle(isOn: $isUsingFaceID) {
                            
                            Label {
                                Text("USE_BIOMETRICS_STRING")
                            } icon: {
                                Image(systemName: "faceid")
                            }
                            
                        }
                        .onAppear {
                            isUsingFaceID = useFaceID
                        }
                        .onChange(of: isUsingFaceID) { oldValue, newValue in
                            if oldValue == false && newValue == true {
                                if !settingsAuthenticated{
                                    authenticate()
                                }
                            }
                            if newValue == false {
                                settingsAuthenticated = false
                                UserDefaults.standard.set(false, forKey: "settings:settingsAuthenticated")
                                isUsingFaceID = false
                                UserDefaults.standard.set(false, forKey: "settings:useFaceID")
                            }
                        }
                        
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
            
            .fullScreenCover(isPresented: $isPinPadPresented) {
                PinPadView(pinAction: $pinAction)
                    .presentationBackground(.thinMaterial)
                    .onDisappear {
                        isLockingAccess = lockAccess
                    }
                    
            }
        }
    }
    
    @State private var pin: String = ""
    
    private func handlePin() {
        let keychain: KeychainWrapper = KeychainWrapper()
        
        if keychain.getPin() == nil {
            pinAction = .SAVE
            isPinPadPresented.toggle()
        }
    }
    
    private func deletePin() {
        
        pinAction = .DELETE
        isPinPadPresented = true
        
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
                    isUsingFaceID = true
                    UserDefaults.standard.set(isUsingFaceID, forKey: "settings:useFaceID")
                    if !settingsAuthenticated {
                        settingsAuthenticated = true
                        UserDefaults.standard.set(true, forKey: "settings:settingsAuthenticated")
                    }
                } else {
                    isUsingFaceID = false
                }
            }
        } else {
            isUsingFaceID = false
        }
    }
}

#Preview {
    SettingsView()
}
