//
//  OnboardingPage.swift
//  SpellPlayUITests
//
//  Created on [Date]
//

import XCTest

class OnboardingPage: BasePage {
    // MARK: - Properties
    var getStartedButton: XCUIElement {
        app.buttons["Onboarding_GetStartedButton"]
    }
    
    var onboardingText: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Mode'")).firstMatch
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func dismissAsParent() -> ParentHomePage {
        waitForElement(getStartedButton)
        getStartedButton.tap()
        sleep(1) // Wait for navigation
        return ParentHomePage(app: app)
    }
    
    func dismissAsChild() -> ChildHomePage {
        waitForElement(getStartedButton)
        getStartedButton.tap()
        sleep(1) // Wait for navigation
        return ChildHomePage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyOnboardingContent(for role: TestHelpers.TestUserRole) -> Bool {
        let expectedText = role == .parent ? "Parent Mode" : "Practice Mode"
        let textElement = app.staticTexts[expectedText]
        return waitForElement(textElement)
    }
}

