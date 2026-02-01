import XCTest

class EditTestPage: BasePage {
    // MARK: - Properties

    var testNameField: XCUIElement {
        app.textFields["EditTest_TestNameField"]
    }

    var wordTextEditor: XCUIElement {
        app.textViews["EditTest_WordTextEditor"]
    }

    var addWordsButton: XCUIElement {
        app.buttons["EditTest_AddWordsButton"]
    }

    var saveButton: XCUIElement {
        app.buttons["EditTest_SaveButton"]
    }

    var cancelButton: XCUIElement {
        app.buttons["EditTest_CancelButton"]
    }

    // MARK: - Initializer

    override init(app: XCUIApplication) {
        super.init(app: app)
    }

    // MARK: - Action Methods

    func updateTestName(_ name: String) -> Self {
        waitForElement(testNameField)
        testNameField.tap()
        testNameField.clearText()
        testNameField.typeText(name)
        return self
    }

    func addWords(_ words: String) -> Self {
        waitForElement(wordTextEditor)
        wordTextEditor.tap()
        wordTextEditor.clearText()
        wordTextEditor.typeText(words)
        tapAddWords()
        return self
    }

    func tapAddWords() -> Self {
        waitForElement(addWordsButton)
        addWordsButton.tap()
        return self
    }

    func removeWord(_ word: String) -> Self {
        let wordElement = app.staticTexts["EditTest_Word_\(word)"]
        if wordElement.exists {
            // Find the delete button near this word
            let deleteButton = app.buttons.containing(NSPredicate(format: "identifier CONTAINS 'minus'")).firstMatch
            if deleteButton.exists {
                deleteButton.tap()
            }
        }
        return self
    }

    func tapTTSButton(for word: String) -> Self {
        let wordElement = app.staticTexts["EditTest_Word_\(word)"]
        if wordElement.exists {
            // Find the speaker button near this word
            let speakerButton = app.buttons.containing(NSPredicate(format: "identifier CONTAINS 'speaker'")).firstMatch
            if speakerButton.exists {
                speakerButton.tap()
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

    func verifyTestName(_ name: String) -> Bool {
        testNameField.value as? String == name
    }

    func verifyWordExists(_ word: String) -> Bool {
        let wordElement = app.staticTexts["EditTest_Word_\(word)"]
        return waitForElement(wordElement)
    }
}
