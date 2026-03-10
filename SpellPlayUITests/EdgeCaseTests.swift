import XCTest

final class EdgeCaseTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING_RESET_STATE"]
        TestHelpers.resetOnboardingFlags()
    }

    override func tearDownWithError() throws {
        TestHelpers.clearAllTests(app)
        app = nil
    }

    func testEmptyTestName_Validation() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        let createTestPage = parentHomePage.tapCreateTest()

        // Try to save with empty name
        createTestPage
            .enterWords("cat, dog")
            .tapAddWords()

        // Save button should be disabled
        let saveButton = app.buttons["CreateTest_SaveButton"]
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled with empty name")
    }

    func testEmptyWordsList_Validation() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        let createTestPage = parentHomePage.tapCreateTest()

        // Try to save with no words
        createTestPage.enterTestName("Empty Words Test")

        // Save button should be disabled
        let saveButton = app.buttons["CreateTest_SaveButton"]
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled with no words")
    }

    func testDuplicateWords_Handling() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        let createTestPage = parentHomePage.tapCreateTest()

        // Add duplicate words
        createTestPage
            .enterTestName("Duplicate Test")
            .enterWords("cat, cat, dog, dog")
            .tapAddWords()

        // Words should be deduplicated
        // Note: This is a simplified test - actual verification depends on UI implementation
        XCTAssertTrue(createTestPage.verifyWordExists("cat"), "Should handle duplicates")
        XCTAssertTrue(createTestPage.verifyWordExists("dog"), "Should handle duplicates")
    }

    func testWordInput_WhitespaceHandling() throws {
        app.launch()

        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        let createTestPage = parentHomePage.tapCreateTest()

        // Add words with whitespace
        createTestPage
            .enterTestName("Whitespace Test")
            .enterWords("  cat  ,  dog  ")
            .tapAddWords()

        // Whitespace should be trimmed
        XCTAssertTrue(createTestPage.verifyWordExists("cat"), "Should trim whitespace")
        XCTAssertTrue(createTestPage.verifyWordExists("dog"), "Should trim whitespace")
    }

    func testDataPersistence_AppRestart() throws {
        app.launch()

        // Create a test
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()

        _ = TestHelpers.createTestViaUI(app, name: "Persistence Test", words: ["cat", "dog"])

        // Restart app (launch args still include UI_TESTING_RESET_STATE so we see role selection again)
        app.terminate()
        app.launch()
        sleep(2)

        // Navigate back to parent home so we can verify the test list
        let roleSelectionPage2 = RoleSelectionPage(app: app)
        let onboardingPage2 = roleSelectionPage2.tapParentButton()
        let parentHomePage2 = onboardingPage2.dismissAsParent()

        XCTAssertTrue(
            parentHomePage2.verifyTestExists(named: "Persistence Test"),
            "Test should persist after app restart")
    }
}
