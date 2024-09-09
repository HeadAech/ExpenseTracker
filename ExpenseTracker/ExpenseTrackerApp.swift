//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData
import TipKit
import AppIntents

@main
struct ExpenseTrackerApp: App {
    //    var sharedModelContainer: ModelContainer = {
//            let modelConfigurationExpense = ModelConfiguration(for: Expense.self, isStoredInMemoryOnly: false)
//            let modelConfigurationTag = ModelConfiguration(for: Tag.self, isStoredInMemoryOnly: false)
//    
    //        let schema: Schema {[
    //            Expense.self,
    //            Tag.self
    //        ]}
    //
    //
    //        do {
    //            return try ModelContainer(schema: schema, configurations: modelConfigurationExpense, modelConfigurationTag)
    //        } catch {
    //            fatalError("Could not create ModelContainer: \(error)")
    //        }
    //    }()
    
    let sharedModelContainer: ModelContainer

    @Environment(\.scenePhase) private var scenePhase
    
    private var gradientColors: [Int: Color] = Colors().gradientColors
    @AppStorage("settings:gradientColorIndex") var gradientColorIndex: Int = 0
    
    @AppStorage("settings:lockAccess") var lockAccess: Bool = false
    @AppStorage("settings:useFaceID") var useFaceID: Bool = false
    
    @State private var pin: String = ""
    
    @State private var isPinPadPresented: Bool = false
    
    @State private var locked: Bool = false
    @State private var authenticationAttempted = false
    
    @State private var pinAction : PinAction = .CONFIRM
    
    @State private var blurAmount: CGFloat = 0
    init() {
        do {
            // Initialize the ModelContainer for both Expense and Tag models
            sharedModelContainer = try ModelContainer(for: Expense.self, Tag.self)
            
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        if lockAccess {
            locked = true
            isPinPadPresented = true
            blurAmount = 15
        }
    }
    
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure([
                        .datastoreLocation(.applicationDefault)
                        
                    ])
                }
                .blur(radius: blurAmount)
                .animation(.smooth, value: locked)
                .onChange(of: scenePhase, { oldPhase, newPhase in
                    if newPhase == .active {
                        if lockAccess && !authenticationAttempted {
                            locked = true
                            isPinPadPresented = true
                            authenticationAttempted = true
                            
                        }
                        
                        if lockAccess && !locked {
                            withAnimation {
                                blurAmount = 0
                            }
                        }
                    }
                    
                    if newPhase == .inactive {
                        if lockAccess {
                            withAnimation{
                                blurAmount = 15
                            }
                        }
                    }
                    
                    if newPhase == .background {
                        
                        if lockAccess{
                            locked = true
                            authenticationAttempted = false
                            withAnimation{
                                blurAmount = 20
                            }
                        }
                        
                    }
                })
                .fullScreenCover(isPresented: $isPinPadPresented) {
                    PinPadView(canDismiss: false, useBiometrics: useFaceID, pinAction: $pinAction)
                        .onDisappear {
                            withAnimation {
                                locked = false
                                withAnimation{
                                    blurAmount = 0
                                }
                            }
                        }
                }
                .tint(Colors().getColor(for: gradientColorIndex))
        }
        .modelContainer(sharedModelContainer)
        
    }
    
    private func confirmPin() -> Bool{
        let keychain: KeychainWrapper = KeychainWrapper()
        
        if keychain.getPin() == pin {
            return true
        }
        return false
    }
}
