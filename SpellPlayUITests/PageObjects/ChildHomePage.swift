import CoreGraphics
import XCTest

class ChildHomePage: BasePage {
    // MARK: - Properties

    var testCards: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'TestCard_'"))
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
        // Child home uses Button for test cards
        let card = app.buttons["TestCard_\(name)"]
        _ = waitForElement(card, timeout: 10.0)
        if !card.isHittable { app.swipeUp() }
        // Use coordinate tap so the sheet opens reliably (avoids hit point -1,-1 in scroll views)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(2) // Allow Word Review sheet to present
        let startButton = app.buttons["WordReview_StartButton"]
        _ = waitForElement(startButton, timeout: 10.0)
        startButton.tap()
        sleep(1) // Wait for Practice screen
        return PracticePage(app: app)
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

    func verifyStreakDisplayed(_ streak: Int) -> Bool {
        if streak > 0 {
            return waitForElement(streakIndicator)
        }
        return true // If streak is 0, indicator shouldn't be displayed
    }
}
