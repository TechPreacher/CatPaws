//
//  MenuBarUITests.swift
//  CatPawsUITests
//
//  Created on 2026-01-15.
//

import XCTest

final class MenuBarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Skip onboarding so the app launches as a pure menu bar app
        // without showing the onboarding window (which would bring it to foreground)
        app.launchArguments = ["-catpaws.onboarding.completed", "true"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        // Menu bar apps (LSUIElement=true) run as background processes
        // They don't enter runningForeground state - check for runningBackground instead
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5), "Menu bar app should launch as background process")
    }

    // MARK: - Placeholder Tests
    // Add menu bar interaction tests here when implementing features
    // Example: testMenuBarIconAppears, testPopoverOpens, etc.
}
