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
        _ = waitForElement(parentButton, timeout: 10.0)
        parentButton.tap()
        return OnboardingPage(app: app)
    }

    func tapChildButton() -> OnboardingPage {
        _ = waitForElement(childButton, timeout: 10.0)
        childButton.tap()
        return OnboardingPage(app: app)
    }

    // MARK: - Verification Methods

    func verifyWelcomeText() -> Bool {
        waitForElement(welcomeText)
    }
}
