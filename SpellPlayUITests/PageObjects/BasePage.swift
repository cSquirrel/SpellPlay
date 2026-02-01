import XCTest

class BasePage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    /// Wait for element to appear
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Wait for element to disappear
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Safely tap element if it exists
    func tapIfExists(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 2.0) {
            element.tap()
        }
    }

    /// Check if element is visible
    func isElementVisible(_ element: XCUIElement) -> Bool {
        element.exists && element.isHittable
    }

    /// Scroll to element if needed
    func scrollToElement(_ element: XCUIElement) {
        if !element.isHittable {
            app.swipeUp()
        }
    }
}
