//
//  Tip.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 04.09.2024.
//

import Foundation
import TipKit

struct AddExpenseTip: Tip {
    var title : Text {
        Text("Dodaj nowy wydatek")
    }
    
    var message: Text? {
        Text("Stuknij tutaj, aby dodać nowy wydatek.")
    }
    
    var image: Image? {
        Image(systemName: "dollarsign.circle.fill")
    }
}
