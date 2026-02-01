import XCTest

class TestHelpers {
    enum TestUserRole: String {
        case parent
        case child
    }

    static func launchAppWithRole(_ app: XCUIApplication, role: TestUserRole) -> Any {
        app.launch()

        // Wait for app to be ready
        sleep(2)

        // Check if role selection is needed
        let roleSelectionPage = RoleSelectionPage(app: app)
        if roleSelectionPage.verifyWelcomeText() {
            let onboardingPage = role == .parent ? roleSelectionPage.tapParentButton() : roleSelectionPage
                .tapChildButton()
            if role == .parent {
                return onboardingPage.dismissAsParent()
            } else {
                return onboardingPage.dismissAsChild()
            }
        }

        // If already on a home page, return appropriate page
        if app.navigationBars["My Spelling Tests"].exists {
            return ParentHomePage(app: app)
        } else {
            return ChildHomePage(app: app)
        }
    }

    static func createTestViaUI(_ app: XCUIApplication, name: String, words: [String]) -> ParentHomePage {
        let parentHomePage = ParentHomePage(app: app)
        let createTestPage = parentHomePage.tapCreateTest()

        createTestPage
            .enterTestName(name)
            .enterWords(words.joined(separator: ", "))
            .tapAddWords()
            .tapSave()

        return ParentHomePage(app: app)
    }

    static func clearAllTests(_ app: XCUIApplication) {
        let parentHomePage = ParentHomePage(app: app)

        // Delete all tests by tapping delete buttons
        // This is a simplified approach - in practice, you might need to iterate through all tests
        let testCards = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'TestCard_'"))
        for i in 0 ..< testCards.count {
            if let card = testCards.element(boundBy: i).firstMatch as? XCUIElement, card.exists {
                card.swipeLeft()
                let deleteButton = app.buttons["Delete"]
                if deleteButton.exists {
                    deleteButton.tap()
                }
            }
        }
    }

    static func resetOnboardingFlags() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding_parent")
        defaults.removeObject(forKey: "hasCompletedOnboarding_child")
        defaults.removeObject(forKey: "selectedRole")
    }

    static func waitForAppToBeReady(_ app: XCUIApplication, timeout: TimeInterval = 5.0) {
        // Wait for app to finish initializing
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app)
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
    }
}
