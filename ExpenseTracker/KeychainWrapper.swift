//
//  KeychainWrapper.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 09.09.2024.
//

import Foundation
import Security

class KeychainWrapper {
    
    public func addPin(pin: String) {
        let pinData: Data = pin.data(using: .utf8)!
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppPin",
            kSecValueData as String: pinData,
            kSecAttrLabel as String: "ExpenseTrackerAppPin"
        ]
        
        if SecItemAdd(attributes as CFDictionary, nil) == noErr{
            print("Pin added to keychain.")
        } else {
            print("Pin could not be added to keychain.")
        }
    }
    
    public func getPin() -> String? {
        let label: String = "ExpenseTrackerAppPin"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppPin",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecAttrLabel as String: label
        ]
        
        var item: CFTypeRef?
        
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            if let attributes: [String: Any] = item as? [String: Any],
               let data: Data = attributes[kSecValueData as String] as? Data,
               let pin: String = String(data: data, encoding: .utf8) {
                return pin
            }
        } else {
            print("Could not fetch app pin.")
        }
        
        return nil
    }
    
    public func setPin(_ pin: String) {
        let label: String = "ExpenseTrackerAppPin"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppPin",
            kSecAttrLabel as String: label
        ]
        
        let attributes: [String: Any] = [kSecValueData as String: pin.data(using: .utf8)!]
        
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == noErr {
            print("Pin was changed")
        } else {
            print("Something went wrong trying to update pin")
        }
    }
    
    public func deletePin() {
        let label: String = "ExpenseTrackerAppPin"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppPin",
            kSecAttrLabel as String: label
        ]

        if SecItemDelete(query as CFDictionary) == noErr {
            print("Pin removed successfully from the keychain")
        } else {
            print("Something went wrong trying to remove pin from the keychain")
        }
    }
}

        
