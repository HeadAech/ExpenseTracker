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
                                           2: Color.green, 3: Color.mint, 4: Color.purple]
    init() {}
    
    func getColor(for index: Int) -> Color {
        return gradientColors[index] ?? .blue
    }
}
