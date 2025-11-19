//
//  RoleSwitcherPage.swift
//  WordCraftUITests
//
//  Created on [Date]
//

import XCTest

class RoleSwitcherPage: BasePage {
    // MARK: - Properties
    var parentButton: XCUIElement {
        app.buttons["RoleSwitcher_ParentButton"]
    }
    
    var childButton: XCUIElement {
        app.buttons["RoleSwitcher_ChildButton"]
    }
    
    var doneButton: XCUIElement {
        app.buttons["Done"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func switchToParent() -> ParentHomePage {
        waitForElement(parentButton)
        parentButton.tap()
        sleep(1) // Wait for navigation
        return ParentHomePage(app: app)
    }
    
    func switchToChild() -> ChildHomePage {
        waitForElement(childButton)
        childButton.tap()
        sleep(1) // Wait for navigation
        return ChildHomePage(app: app)
    }
    
    func dismissAsParent() -> ParentHomePage {
        if doneButton.exists {
            doneButton.tap()
            sleep(1)
        }
        return ParentHomePage(app: app)
    }
    
    func dismissAsChild() -> ChildHomePage {
        if doneButton.exists {
            doneButton.tap()
            sleep(1)
        }
        return ChildHomePage(app: app)
    }
}

