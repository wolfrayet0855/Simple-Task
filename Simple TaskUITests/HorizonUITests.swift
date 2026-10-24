import XCTest

final class HorizonUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(_ extra: [String] = [], demo: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-inMemoryStore", "-skipPermission"] + (demo ? ["-seedDemo"] : ["-skipOnboarding"]) + extra
        app.launch()
        return app
    }

    private func card(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
    }

    func testNoAlertsOnLaunch() {
        let app = launch()
        XCTAssertTrue(card(app, "Groceries").waitForExistence(timeout: 15))
        sleep(2)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func testCaptureAddsCardToInHand() {
        let app = launch(demo: false)
        let field = app.textFields["Capture"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText("Pay rent")
        app.buttons["Add"].tap()
        XCTAssertTrue(card(app, "Pay rent").waitForExistence(timeout: 5))
    }

    func testReturnKeySubmitsCapture() {
        let app = launch(demo: false)
        let field = app.textFields["Capture"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText("Call mum\n")
        XCTAssertTrue(card(app, "Call mum").waitForExistence(timeout: 5))
    }

    func testHoldCompletesAndUndoRestores() {
        let app = launch()
        let groceries = card(app, "Groceries")
        XCTAssertTrue(groceries.waitForExistence(timeout: 15))
        groceries.press(forDuration: 0.9)
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3), "toast with Undo appears")
        undo.tap()
        XCTAssertTrue(card(app, "Groceries").waitForExistence(timeout: 3))
    }

    func testShortPressDoesNotComplete() {
        let app = launch()
        let groceries = card(app, "Groceries")
        XCTAssertTrue(groceries.waitForExistence(timeout: 15))
        groceries.press(forDuration: 0.2)
        XCTAssertFalse(app.buttons["Undo"].waitForExistence(timeout: 1))
    }

    func testTapOpensTaskSheet() {
        let app = launch()
        let groceries = card(app, "Groceries")
        XCTAssertTrue(groceries.waitForExistence(timeout: 15))
        groceries.tap()
        XCTAssertTrue(app.buttons["Hold to finish"].waitForExistence(timeout: 5))
        XCTAttachment.screenshot(app, named: "task-sheet")
    }

    func testRecoveryScreenAppearsOnForcedFailure() {
        let app = launch(["-failRelocation"], demo: false)
        XCTAssertTrue(app.staticTexts["Your tasks are safe."].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Try again"].exists)
    }

    func testOnboardingShowsOnFirstRunAndSkips() {
        let app = XCUIApplication()
        app.launchArguments = ["-inMemoryStore", "-skipPermission", "-resetOnboarding"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Your days, laid out ahead."].waitForExistence(timeout: 20))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.textFields["Capture"].waitForExistence(timeout: 5))
    }
}

private extension XCTestCase {}
extension XCTAttachment {
    @discardableResult
    static func screenshot(_ app: XCUIApplication, named name: String) -> XCTAttachment {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; return a
    }
}
