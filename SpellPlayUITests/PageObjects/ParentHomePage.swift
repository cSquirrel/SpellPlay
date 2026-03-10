import XCTest

class ParentHomePage: BasePage {
    // MARK: - Properties

    var createTestButton: XCUIElement {
        app.buttons["ParentHome_CreateTestButton"]
    }

    var createTestToolbarButton: XCUIElement {
        app.buttons["ParentHome_CreateTestToolbarButton"]
    }

    var testCards: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'TestCard_'"))
    }

    var emptyStateText: XCUIElement {
        app.staticTexts["ParentHome_EmptyStateText"]
    }

    var settingsButton: XCUIElement {
        app.buttons["ParentHome_SettingsButton"]
    }

    // MARK: - Initializer

    override init(app: XCUIApplication) {
        super.init(app: app)
    }

    // MARK: - Action Methods

    func tapCreateTest() -> CreateTestPage {
        // Try toolbar button first, then main button
        if createTestToolbarButton.exists {
            createTestToolbarButton.tap()
        } else {
            waitForElement(createTestButton)
            createTestButton.tap()
        }
        return CreateTestPage(app: app)
    }

    func tapTestCard(named name: String) -> EditTestPage {
        let card = element(matchingIdentifier: "TestCard_\(name)")
        _ = waitForElement(card, timeout: 10.0)
        card.tap()
        return EditTestPage(app: app)
    }

    func deleteTest(named name: String) -> Self {
        let card = element(matchingIdentifier: "TestCard_\(name)")
        if card.waitForExistence(timeout: 5) {
            // Swipe to delete or tap delete button
            card.swipeLeft()
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                deleteButton.tap()
            }
        }
        return self
    }

    func tapSettings() -> RoleSwitcherPage {
        waitForElement(settingsButton)
        settingsButton.tap()
        return RoleSwitcherPage(app: app)
    }

    // MARK: - Verification Methods

    func verifyTestExists(named name: String) -> Bool {
        let card = element(matchingIdentifier: "TestCard_\(name)")
        return waitForElement(card, timeout: 10.0)
    }

    func verifyEmptyState() -> Bool {
        waitForElement(emptyStateText, timeout: 10.0)
    }

    // MARK: - Query Methods

    func getTestCount() -> Int {
        testCards.count
    }
}
