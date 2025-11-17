//
//  ChildFlowTests.swift
//  SpellPlayUITests
//
//  Created on [Date]
//

import XCTest

final class ChildFlowTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        TestHelpers.resetOnboardingFlags()
    }
    
    override func tearDownWithError() throws {
        TestHelpers.clearAllTests(app)
        app = nil
    }
    
    func testChildHome_EmptyState() throws {
        app.launch()
        
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapChildButton()
        let childHomePage = onboardingPage.dismissAsChild()
        
        XCTAssertTrue(childHomePage.verifyEmptyState(), "Should show empty state when no tests available")
    }
    
    func testChildHome_TestList() throws {
        app.launch()
        
        // Create a test as parent first
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Child Test", words: ["cat", "dog", "bird"])
        
        // Switch to child role
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        
        XCTAssertTrue(childHomePage.verifyTestExists(named: "Child Test"), "Test should be visible to child")
    }
    
    func testPracticeFlow_CorrectAnswer() throws {
        app.launch()
        
        // Setup: Create test as parent
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Practice Test", words: ["cat"])
        
        // Switch to child and start practice
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        let practicePage = childHomePage.tapTestCard(named: "Practice Test")
        
        // Enter correct answer
        practicePage
            .enterAnswer("cat")
            .tapSubmit()
        
        // Wait for feedback
        sleep(2)
        
        XCTAssertTrue(practicePage.verifyCorrectFeedback(), "Should show correct feedback")
    }
    
    func testPracticeFlow_IncorrectAnswer() throws {
        app.launch()
        
        // Setup: Create test as parent
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Incorrect Test", words: ["cat"])
        
        // Switch to child and start practice
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        let practicePage = childHomePage.tapTestCard(named: "Incorrect Test")
        
        // Enter incorrect answer
        practicePage
            .enterAnswer("dog")
            .tapSubmit()
        
        // Wait for feedback
        sleep(2)
        
        XCTAssertTrue(practicePage.verifyIncorrectFeedback(), "Should show incorrect feedback")
    }
    
    func testPracticeFlow_RoundTransition() throws {
        app.launch()
        
        // Setup: Create test as parent
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Round Test", words: ["cat", "dog"])
        
        // Switch to child and start practice
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        let practicePage = childHomePage.tapTestCard(named: "Round Test")
        
        // Misspell words to trigger round transition
        practicePage
            .enterAnswer("incorrect1")
            .tapSubmit()
        
        sleep(2)
        
        practicePage
            .enterAnswer("incorrect2")
            .tapSubmit()
        
        // Wait for round transition
        let roundTransitionPage = practicePage.waitForRoundTransition()
        
        XCTAssertTrue(roundTransitionPage.verifyRoundNumber(2), "Should show round 2")
        XCTAssertTrue(roundTransitionPage.getMisspelledWordsCount() > 0, "Should show misspelled words")
    }
    
    func testPracticeFlow_IterativeRounds() throws {
        app.launch()
        
        // Setup: Create test as parent
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Iterative Test", words: ["cat"])
        
        // Switch to child and start practice
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        let practicePage = childHomePage.tapTestCard(named: "Iterative Test")
        
        // Round 1: Misspell
        practicePage
            .enterAnswer("incorrect")
            .tapSubmit()
        
        sleep(2)
        
        // Wait for round transition
        let roundTransitionPage = practicePage.waitForRoundTransition()
        XCTAssertTrue(roundTransitionPage.verifyMisspelledWordExists("cat"), "Should show misspelled word")
        
        // Start next round
        let practicePage2 = roundTransitionPage.tapStartRound()
        
        // Round 2: Spell correctly
        practicePage2
            .enterAnswer("cat")
            .tapSubmit()
        
        // Wait for summary
        let summaryPage = practicePage2.waitForSummary()
        XCTAssertTrue(summaryPage.verifyRoundsCompleted(2), "Should show 2 rounds completed")
    }
    
    func testPracticeSummary_Display() throws {
        app.launch()
        
        // Setup: Create test and complete practice
        let roleSelectionPage = RoleSelectionPage(app: app)
        let onboardingPage = roleSelectionPage.tapParentButton()
        let parentHomePage = onboardingPage.dismissAsParent()
        
        _ = TestHelpers.createTestViaUI(app, name: "Summary Test", words: ["cat"])
        
        // Switch to child and complete practice
        let roleSwitcherPage = parentHomePage.tapSettings()
        let childHomePage = roleSwitcherPage.switchToChild()
        let practicePage = childHomePage.tapTestCard(named: "Summary Test")
        
        practicePage
            .enterAnswer("cat")
            .tapSubmit()
        
        let summaryPage = practicePage.waitForSummary()
        
        XCTAssertTrue(summaryPage.verifyRoundsCompleted(1), "Should show rounds completed")
    }
}

