import XCTest

class ChildHomePage: BasePage {
    // MARK: - Properties

    var testCards: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'ChildTestCard_'"))
    }

    var emptyStateText: XCUIElement {
        app.staticTexts["ChildHome_EmptyStateText"]
    }

    var streakIndicator: XCUIElement {
        app.otherElements.containing(NSPredicate(format: "identifier CONTAINS 'Streak'")).firstMatch
    }

    var settingsButton: XCUIElement {
        app.buttons["ChildHome_SettingsButton"]
    }

    // MARK: - Initializer

    override init(app: XCUIApplication) {
        super.init(app: app)
    }

    // MARK: - Action Methods

    func tapTestCard(named name: String) -> PracticePage {
        let card = app.otherElements["ChildTestCard_\(name)"]
        waitForElement(card)
        card.tap()
        sleep(1) // Wait for navigation
        return PracticePage(app: app)
    }

    func tapSettings() -> RoleSwitcherPage {
        waitForElement(settingsButton)
        settingsButton.tap()
        return RoleSwitcherPage(app: app)
    }

    // MARK: - Verification Methods

    func verifyTestExists(named name: String) -> Bool {
        let card = app.otherElements["ChildTestCard_\(name)"]
        return waitForElement(card)
    }

    func verifyEmptyState() -> Bool {
        waitForElement(emptyStateText)
    }

    func verifyStreakDisplayed(_ streak: Int) -> Bool {
        if streak > 0 {
            return waitForElement(streakIndicator)
        }
        return true // If streak is 0, indicator shouldn't be displayed
    }
}
