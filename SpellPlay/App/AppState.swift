//
//  AppState.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import SwiftUI

@Observable
class AppState {
    var currentRole: UserRole?
    var selectedTest: SpellingTest?
    
    /// Checks if onboarding has been completed for a specific role
    func hasCompletedOnboarding(for role: UserRole) -> Bool {
        let key = "hasCompletedOnboarding_\(role.rawValue)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Marks onboarding as completed for a specific role
    func setOnboardingCompleted(for role: UserRole, completed: Bool) {
        let key = "hasCompletedOnboarding_\(role.rawValue)"
        UserDefaults.standard.set(completed, forKey: key)
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

