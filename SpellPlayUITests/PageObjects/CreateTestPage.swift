//
//  CreateTestPage.swift
//  WordCraftUITests
//
//  Created on [Date]
//

import XCTest

class CreateTestPage: BasePage {
    // MARK: - Properties
    var testNameField: XCUIElement {
        app.textFields["CreateTest_TestNameField"]
    }
    
    var wordTextEditor: XCUIElement {
        app.textViews["CreateTest_WordTextEditor"]
    }
    
    var addWordsButton: XCUIElement {
        app.buttons["CreateTest_AddWordsButton"]
    }
    
    var saveButton: XCUIElement {
        app.buttons["CreateTest_SaveButton"]
    }
    
    var cancelButton: XCUIElement {
        app.buttons["CreateTest_CancelButton"]
    }
    
    // MARK: - Initializer
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Action Methods
    func enterTestName(_ name: String) -> Self {
        waitForElement(testNameField)
        testNameField.tap()
        testNameField.clearText()
        testNameField.typeText(name)
        return self
    }
    
    func enterWords(_ words: String) -> Self {
        waitForElement(wordTextEditor)
        wordTextEditor.tap()
        wordTextEditor.clearText()
        wordTextEditor.typeText(words)
        return self
    }
    
    func tapAddWords() -> Self {
        waitForElement(addWordsButton)
        addWordsButton.tap()
        return self
    }
    
    func tapTTSButton(for word: String) -> Self {
        // TTS buttons don't have specific identifiers, so we'll find by proximity to word text
        let wordElement = app.staticTexts["CreateTest_Word_\(word)"]
        if wordElement.exists {
            // Find the speaker button near this word
            let speakerButton = app.buttons.containing(NSPredicate(format: "identifier CONTAINS 'speaker'")).firstMatch
            if speakerButton.exists {
                speakerButton.tap()
            }
        }
        return self
    }
    
    func removeWord(_ word: String) -> Self {
        let wordElement = app.staticTexts["CreateTest_Word_\(word)"]
        if wordElement.exists {
            // Find the delete button near this word
            let deleteButton = app.buttons.containing(NSPredicate(format: "identifier CONTAINS 'minus'")).firstMatch
            if deleteButton.exists {
                deleteButton.tap()
            }
        }
        return self
    }
    
    func tapSave() -> ParentHomePage {
        waitForElement(saveButton)
        saveButton.tap()
        sleep(1) // Wait for navigation
        return ParentHomePage(app: app)
    }
    
    func tapCancel() -> ParentHomePage {
        waitForElement(cancelButton)
        cancelButton.tap()
        sleep(1) // Wait for navigation
        return ParentHomePage(app: app)
    }
    
    // MARK: - Verification Methods
    func verifyWordExists(_ word: String) -> Bool {
        let wordElement = app.staticTexts["CreateTest_Word_\(word)"]
        return waitForElement(wordElement)
    }
    
    func verifyAddWordsButtonEnabled() -> Bool {
        return addWordsButton.isEnabled
    }
}

// Extension to clear text fields
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}

