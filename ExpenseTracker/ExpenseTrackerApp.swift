//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import SwiftData
import TipKit

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

    init() {
        do {
            // Initialize the ModelContainer for both Expense and Tag models
            sharedModelContainer = try ModelContainer(for: Expense.self, Tag.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
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
        }
        .modelContainer(sharedModelContainer)
        
    }
}
