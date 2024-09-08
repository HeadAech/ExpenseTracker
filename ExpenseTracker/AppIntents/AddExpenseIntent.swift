//
//  AddExpenseIntent.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 08.09.2024.
//

import Foundation
import AppIntents
import SwiftUI
import SwiftData

class ExpenseAdder {
    @Environment(\.modelContext) private var modelContext
    
    public func addExpense(expense: Expense){
        modelContext.insert(expense)
    }
}

struct AddExpenseIntent: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "AddExpenseIntentIntent"

    static var title: LocalizedStringResource = "Add Expense Intent"
    static var description = IntentDescription("")

    @Parameter(title: "Name", default: "Expense")
    var name: String?

    @Parameter(title: "Amount", default: 0)
    var amount: Double?

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$name
            \.$amount
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$name, \.$amount)) { name, amount in
            DisplayRepresentation(
                title: "",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        
        let expense = Expense(name: name ?? "", date: .now, value: amount ?? 0)
        
        ExpenseAdder().addExpense(expense: expense)
        
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func nameParameterDisambiguationIntro(count: Int, name: String) -> Self {
        "There are \(count) options matching ‘\(name)’."
    }
    static func nameParameterConfirmation(name: String) -> Self {
        "Just to confirm, you wanted ‘\(name)’?"
    }
    static func amountParameterDisambiguationIntro(count: Int, amount: Double) -> Self {
        "There are \(count) options matching ‘\(amount)’."
    }
    static func amountParameterConfirmation(amount: Double) -> Self {
        "Just to confirm, you wanted ‘\(amount)’?"
    }
}

