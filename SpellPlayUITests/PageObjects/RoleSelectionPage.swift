//
//  RoleSelectionPage.swift
//  SpellPlayUITests
//
//  Created on [Date]
//

import XCTest

class RoleSelectionPage: BasePage {
    // MARK: - Properties
    var parentButton: XCUIElement {
        app.buttons["RoleSelection_ParentButton"]
    }
    
    var childButton: XCUIElement {
        app.buttons["RoleSelection_ChildButton"]
    }
    
    var welcomeText: XCUIElement {
        app.staticTexts["RoleSelection_WelcomeText"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func tapParentButton() -> OnboardingPage {
        waitForElement(parentButton)
        parentButton.tap()
        return OnboardingPage(app: app)
    }
    
    func tapChildButton() -> OnboardingPage {
        waitForElement(childButton)
        childButton.tap()
        return OnboardingPage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyWelcomeText() -> Bool {
        return waitForElement(welcomeText)
    }
}

