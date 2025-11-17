//
//  PracticePage.swift
//  SpellPlayUITests
//
//  Created on [Date]
//

import XCTest

class PracticePage: BasePage {
    // MARK: - Properties
    var progressText: XCUIElement {
        app.staticTexts["Practice_ProgressText"]
    }
    
    var wordInputField: XCUIElement {
        app.textFields["WordInput_TextField"]
    }
    
    var submitButton: XCUIElement {
        app.buttons["WordInput_SubmitButton"]
    }
    
    var speakerButton: XCUIElement {
        app.buttons.containing(NSPredicate(format: "identifier CONTAINS 'speaker' OR label CONTAINS 'hear'")).firstMatch
    }
    
    var feedbackMessage: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Correct' OR label CONTAINS 'Try again'")).firstMatch
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func enterAnswer(_ answer: String) -> Self {
        waitForElement(wordInputField)
        wordInputField.tap()
        wordInputField.clearText()
        wordInputField.typeText(answer)
        return self
    }
    
    func tapSubmit() -> Self {
        waitForElement(submitButton)
        submitButton.tap()
        return self
    }
    
    func tapSpeaker() -> Self {
        if speakerButton.exists {
            speakerButton.tap()
        }
        return self
    }
    
    func waitForRoundTransition() -> RoundTransitionPage {
        // Wait for round transition screen to appear
        let roundTitle = app.staticTexts["RoundTransition_RoundTitle"]
        waitForElement(roundTitle, timeout: 10.0)
        return RoundTransitionPage(app: app)
    }
    
    func waitForSummary() -> PracticeSummaryPage {
        // Wait for practice summary to appear
        let roundsCompleted = app.staticTexts["PracticeSummary_RoundsCompleted"]
        waitForElement(roundsCompleted, timeout: 10.0)
        return PracticeSummaryPage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyCurrentWord(_ word: String) -> Bool {
        // The word might be displayed in the speaker button area or elsewhere
        // This is a simplified check - adjust based on actual UI
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(word)'")).firstMatch.exists
    }
    
    func verifyProgress(_ expected: String) -> Bool {
        let progress = progressText.label
        return progress.contains(expected)
    }
    
    func verifyCorrectFeedback() -> Bool {
        let feedback = feedbackMessage
        return feedback.exists && feedback.label.contains("Correct")
    }
    
    func verifyIncorrectFeedback() -> Bool {
        let feedback = feedbackMessage
        return feedback.exists && feedback.label.contains("Try again")
    }
    
    func isInputEnabled() -> Bool {
        return wordInputField.isEnabled
    }
}

