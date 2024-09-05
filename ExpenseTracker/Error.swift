//
//  Error.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 05.09.2024.
//

import Foundation

enum Error {
    case AMOUNT_LESS_THAN_ZERO
    case DATE_FROM_THE_FUTURE
    
    var title: LocalizedStringResource {
        switch self {
            
        case .AMOUNT_LESS_THAN_ZERO: "AMOUNT_LESS_THAN_ZERO_MESSAGE"
        case .DATE_FROM_THE_FUTURE: "DATE_FROM_FUTURE_MESSAGE"
            
        }
    }
}
