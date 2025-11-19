//
//  PracticeSummaryPage.swift
//  WordCraftUITests
//
//  Created on [Date]
//

import XCTest

class PracticeSummaryPage: BasePage {
    // MARK: - Properties
    var roundsCompletedText: XCUIElement {
        app.staticTexts["PracticeSummary_RoundsCompleted"]
    }
    
    var practiceAgainButton: XCUIElement {
        app.buttons["PracticeSummary_PracticeAgainButton"]
    }
    
    var backToTestsButton: XCUIElement {
        app.buttons["PracticeSummary_BackToTestsButton"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func tapPracticeAgain() -> PracticePage {
        waitForElement(practiceAgainButton)
        practiceAgainButton.tap()
        sleep(1) // Wait for navigation
        return PracticePage(app: app)
    }
    
    func tapBackToTests() -> ChildHomePage {
        waitForElement(backToTestsButton)
        backToTestsButton.tap()
        sleep(1) // Wait for navigation
        return ChildHomePage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyRoundsCompleted(_ rounds: Int) -> Bool {
        let text = roundsCompletedText.label
        return text.contains("\(rounds) round")
    }
    
    func verifyStreak(_ streak: Int) -> Bool {
        // Streak might be displayed in a separate element
        // This is a simplified check - adjust based on actual UI
        let streakText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(streak)'")).firstMatch
        return streakText.exists
    }
}

