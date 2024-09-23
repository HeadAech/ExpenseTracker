//
//  Colors.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 31/08/2024.
//

import Foundation
import SwiftUI

class Colors: Identifiable {
    var gradientColors: [Int: Color] = [0: Color.blue, 1: Color.red,
                                        2: Color.green, 3: Color.teal, 4: Color.purple, 5: Color.yellow, 6: Color.pink]
    init() {}
    
    func getColor(for index: Int) -> Color {
        return gradientColors[index] ?? .blue
    }
}
