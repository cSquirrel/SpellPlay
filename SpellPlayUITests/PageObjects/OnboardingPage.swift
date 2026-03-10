import XCTest

class OnboardingPage: BasePage {
    // MARK: - Properties

    var getStartedButton: XCUIElement {
        app.buttons["Onboarding_GetStartedButton"]
    }

    var onboardingText: XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Mode'")).firstMatch
    }

    // MARK: - Initializer

    override init(app: XCUIApplication) {
        super.init(app: app)
    }

    // MARK: - Action Methods

    func dismissAsParent() -> ParentHomePage {
        _ = waitForElement(getStartedButton, timeout: 10.0)
        getStartedButton.tap()
        sleep(1) // Wait for navigation
        return ParentHomePage(app: app)
    }

    func dismissAsChild() -> ChildHomePage {
        _ = waitForElement(getStartedButton, timeout: 10.0)
        getStartedButton.tap()
        sleep(1) // Wait for navigation
        return ChildHomePage(app: app)
    }

    // MARK: - Verification Methods

    func verifyOnboardingContent(for role: TestHelpers.TestUserRole) -> Bool {
        let identifier = role == .parent ? "Onboarding_ParentModeTitle" : "Onboarding_PracticeModeTitle"
        let textElement = app.staticTexts[identifier]
        return waitForElement(textElement, timeout: 10.0)
    }
}
