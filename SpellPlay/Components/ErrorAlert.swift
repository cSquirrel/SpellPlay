//
//  ErrorAlert.swift
//  SpellPlay
//
//  Reusable error alert component for user-facing error messages
//

import SwiftUI

extension View {
    /// Displays an error alert when errorMessage is not nil
    /// - Parameters:
    ///   - errorMessage: Binding to optional error message string
    ///   - retryAction: Optional retry action closure
    func errorAlert(errorMessage: Binding<String?>, retryAction: (() -> Void)? = nil) -> some View {
        self.alert("Error", isPresented: Binding(
            get: { errorMessage.wrappedValue != nil },
            set: { if !$0 { errorMessage.wrappedValue = nil } }
        )) {
            if let retryAction = retryAction {
                Button("Retry", role: .none) {
                    retryAction()
                }
                Button("OK", role: .cancel) {
                    errorMessage.wrappedValue = nil
                }
            } else {
                Button("OK", role: .cancel) {
                    errorMessage.wrappedValue = nil
                }
            }
        } message: {
            if let message = errorMessage.wrappedValue {
                Text(message)
            }
        }
    }
}

