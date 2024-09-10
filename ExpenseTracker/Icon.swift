//
//  Icon.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 05.09.2024.
//

import Foundation

enum Icon: String, RawRepresentable, CaseIterable, Identifiable {
    var id : String { self.rawValue }
    
    case tag = "tag.fill"
    case phone = "phone.fill"
    case video = "video.fill"
    case envelope = "envelope.fill"
    case sun = "sun.max.fill"
    case moon = "moon.fill"
    case sparkles = "sparkles"
    case cloud = "cloud.fill"
    case rainbow = "rainbow"
    case location = "location.fill"
    case car = "car.fill"
    case tram = "tram.fill"
    case bicycle = "bicycle"
    case fuelpump = "fuelpump.fill"
    case binocular = "binoculars.fill"
    case brush = "paintbrush.pointed.fill"
    
    
//    TODO: Add more icons
   
}
