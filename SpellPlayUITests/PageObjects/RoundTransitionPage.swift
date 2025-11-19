//
//  RoundTransitionPage.swift
//  WordCraftUITests
//
//  Created on [Date]
//

import XCTest

class RoundTransitionPage: BasePage {
    // MARK: - Properties
    var roundTitle: XCUIElement {
        app.staticTexts["RoundTransition_RoundTitle"]
    }
    
    var subtitle: XCUIElement {
        app.staticTexts["RoundTransition_Subtitle"]
    }
    
    var misspelledWordsList: XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'RoundTransition_Word_'"))
    }
    
    var startRoundButton: XCUIElement {
        app.buttons["RoundTransition_StartRoundButton"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func tapStartRound() -> PracticePage {
        waitForElement(startRoundButton)
        startRoundButton.tap()
        sleep(1) // Wait for navigation
        return PracticePage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyRoundNumber(_ round: Int) -> Bool {
        let title = roundTitle.label
        return title.contains("Round \(round)")
    }
    
    func verifyMisspelledWordExists(_ word: String) -> Bool {
        let wordElement = app.staticTexts["RoundTransition_Word_\(word)"]
        return waitForElement(wordElement)
    }
    
    // MARK: - Query Methods
    func getMisspelledWordsCount() -> Int {
        return misspelledWordsList.count
    }
}

