//
//  AppState.swift
//  SpellPlay
//
//  Created on [Date]
//

import Foundation
import SwiftUI

@Observable
class AppState {
    var currentRole: UserRole?
    var selectedTest: SpellingTest?
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
        }
    }
    
    var selectedRole: UserRole? {
        get {
            if let roleString = UserDefaults.standard.string(forKey: "selectedRole"),
               let role = UserRole(rawValue: roleString) {
                return role
            }
            return nil
        }
        set {
            if let role = newValue {
                UserDefaults.standard.set(role.rawValue, forKey: "selectedRole")
                currentRole = role
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedRole")
                currentRole = nil
            }
        }
    }
    
    init() {
        if let role = selectedRole {
            currentRole = role
        }
    }
}

