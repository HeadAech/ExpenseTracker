//
//  Tag.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 05.09.2024.
//

import Foundation
import SwiftData

@Model
class Tag: Equatable, Identifiable {
    
    @Attribute(.unique)
    var id: String = UUID().uuidString
    var name: String
    var color: String
    
    var icon: String
    
    
    init(name: String, color: String, icon: String) {
        self.name = name
        self.color = color
        self.icon = icon
    }
    
//    init(name: String, color: String){
//        self.name = name
//        self.color = color
//    }
}
