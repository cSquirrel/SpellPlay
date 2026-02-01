import XCTest

final class RoleSelectionTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        TestHelpers.resetOnboardingFlags()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testRoleSelection_ParentFlow() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        XCTAssertTrue(roleSelectionPage.verifyWelcomeText(), "Welcome text should be displayed")

        let onboardingPage = roleSelectionPage.tapParentButton()
        XCTAssertTrue(onboardingPage.verifyOnboardingContent(for: .parent), "Parent onboarding should be displayed")

        let parentHomePage = onboardingPage.dismissAsParent()
        XCTAssertTrue(parentHomePage.verifyEmptyState(), "Parent home should show empty state")
    }

    func testRoleSelection_ChildFlow() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        XCTAssertTrue(roleSelectionPage.verifyWelcomeText(), "Welcome text should be displayed")

        let onboardingPage = roleSelectionPage.tapChildButton()
        XCTAssertTrue(onboardingPage.verifyOnboardingContent(for: .child), "Child onboarding should be displayed")

        let childHomePage = onboardingPage.dismissAsChild()
        XCTAssertTrue(childHomePage.verifyEmptyState(), "Child home should show empty state")
    }

    func testOnboarding_ParentDismissal() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        // Relaunch app - onboarding should not appear again
        app.terminate()
        app.launch()
        sleep(2)

        // Should go directly to parent home
        XCTAssertTrue(app.navigationBars["My Spelling Tests"].exists, "Should be on parent home without onboarding")
    }

    func testOnboarding_ChildDismissal() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapChildButton()
        let childHomePage = onboardingPage.dismissAsChild()

        // Relaunch app - onboarding should not appear again
        app.terminate()
        app.launch()
        sleep(2)

        // Should go directly to child home
        XCTAssertTrue(app.navigationBars["WordCraft"].exists, "Should be on child home without onboarding")
    }

    func testRoleSwitching() throws {
        app.launch()

        // Start as parent
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        var parentHomePage = onboardingPage.dismissAsParent()

        // Switch to child
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        XCTAssertTrue(childHomePage.verifyEmptyState(), "Should be on child home")

        // Switch back to parent
        let roleSwitcherPage2 = childHomePage.tapSettings()
        parentHomePage = roleSwitcherPage2.switchToParent()
        XCTAssertTrue(parentHomePage.verifyEmptyState(), "Should be on parent home")
    }
}
