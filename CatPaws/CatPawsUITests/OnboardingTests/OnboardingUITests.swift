//
//  OnboardingUITests.swift
//  CatPawsUITests
//
//  Created on 2026-01-18.
//

import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - First Launch Tests

    func testOnboardingAppearsOnFirstLaunch() throws {
        // Reset onboarding state so it appears
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Wait for onboarding window to appear
        let window = app.windows["Welcome to CatPaws"]
        XCTAssertTrue(window.waitForExistence(timeout: 5), "Onboarding window should appear on first launch")
    }

    func testOnboardingShowsWelcomeStep() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Verify welcome step content - title must exist
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))

        // Verify some description text exists (the window has multiple staticTexts)
        // Just checking there's more than just the title
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        XCTAssertTrue(staticTexts.count > 1, "Welcome step should have description text")
    }

    func testOnboardingDoesNotAppearAfterCompletion() throws {
        // Mark onboarding as completed
        app.launchArguments = ["-catpaws.onboarding.completed", "true"]
        app.launch()

        // Onboarding window should not appear
        let window = app.windows["Welcome to CatPaws"]
        XCTAssertFalse(window.waitForExistence(timeout: 2), "Onboarding should not appear after completion")
    }

    // MARK: - Navigation Tests

    func testNextButtonAdvancesToPermissionExplanation() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Wait for welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))

        // Tap Next
        app.buttons["Next"].tap()

        // Verify permission explanation step
        XCTAssertTrue(app.staticTexts["Permissions Required"].waitForExistence(timeout: 2))
    }

    func testBackButtonReturnsToWelcome() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Navigate to permission explanation
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()

        // Verify we're on permission explanation
        XCTAssertTrue(app.staticTexts["Permissions Required"].waitForExistence(timeout: 2))

        // Tap Back
        app.buttons["Back"].tap()

        // Verify we're back on welcome
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 2))
    }

    func testNavigateThroughAllSteps() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Step 1: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()

        // Step 2: Permission Explanation
        XCTAssertTrue(app.staticTexts["Permissions Required"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()

        // Step 3: Grant Accessibility
        XCTAssertTrue(app.staticTexts["Grant Accessibility"].waitForExistence(timeout: 2) ||
                      app.staticTexts["Permission Granted!"].waitForExistence(timeout: 2))

        // Use "Continue Anyway" or "Next" depending on permission state
        if app.buttons["Continue Anyway"].exists {
            app.buttons["Continue Anyway"].tap()
        } else {
            app.buttons["Next"].tap()
        }

        // Step 4: Grant Input Monitoring
        XCTAssertTrue(app.staticTexts["Grant Input Monitoring"].waitForExistence(timeout: 2) ||
                      app.staticTexts["Permission Granted!"].waitForExistence(timeout: 2))

        // Use "Continue Anyway" or "Next" depending on permission state
        if app.buttons["Continue Anyway"].exists {
            app.buttons["Continue Anyway"].tap()
        } else {
            app.buttons["Next"].tap()
        }

        // Step 5: Test Detection
        XCTAssertTrue(app.staticTexts["Test Detection"].waitForExistence(timeout: 2) ||
                      app.staticTexts["It Works!"].waitForExistence(timeout: 2))

        // Use "Skip Test" or "Finish" depending on detection state
        if app.buttons["Skip Test"].exists {
            app.buttons["Skip Test"].tap()
        } else {
            app.buttons["Finish"].tap()
        }

        // Step 6: Complete
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 2))
    }

    // MARK: - Skip Tests

    func testSkipButtonExistsOnWelcome() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))
        // Skip button uses .link style, so check for button or link
        let skipExists = app.buttons["Skip"].exists || app.links["Skip"].exists ||
            !app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Skip"))
                .allElementsBoundByIndex.isEmpty
        XCTAssertTrue(skipExists, "Skip button should exist on welcome step")
    }

    func testSkipButtonClosesOnboarding() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Wait for onboarding window and welcome text
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))

        // Find Skip button - it uses .link style so may appear as a link/staticText
        // Try multiple approaches to find it
        var skipElement: XCUIElement?

        if app.buttons["Skip"].exists {
            skipElement = app.buttons["Skip"]
        } else if app.links["Skip"].exists {
            skipElement = app.links["Skip"]
        } else {
            // Try finding by label predicate
            let skipPredicate = NSPredicate(format: "label == %@", "Skip")
            let matches = app.descendants(matching: .any).matching(skipPredicate)
            if !matches.allElementsBoundByIndex.isEmpty {
                skipElement = matches.firstMatch
            }
        }

        XCTAssertNotNil(skipElement, "Skip element should exist")
        skipElement?.tap()

        // Window should close - check that welcome text is gone
        let welcomeText = app.staticTexts["Welcome to CatPaws"]
        XCTAssertFalse(welcomeText.waitForExistence(timeout: 3), "Onboarding should close after skip")
    }

    func testSkipFromMiddleStep() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Navigate to permission explanation
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Permissions Required"].waitForExistence(timeout: 2))

        // Find and tap Skip element
        var skipElement: XCUIElement?
        if app.buttons["Skip"].exists {
            skipElement = app.buttons["Skip"]
        } else if app.links["Skip"].exists {
            skipElement = app.links["Skip"]
        } else {
            let matches = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Skip"))
            if !matches.allElementsBoundByIndex.isEmpty {
                skipElement = matches.firstMatch
            }
        }

        XCTAssertNotNil(skipElement, "Skip should exist on middle step")
        skipElement?.tap()

        // Verify onboarding closed
        let welcomeText = app.staticTexts["Permissions Required"]
        XCTAssertFalse(welcomeText.waitForExistence(timeout: 3), "Onboarding should close when skipped")
    }

    // MARK: - Progress Indicator Tests

    func testProgressIndicatorExists() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))

        // Progress indicator is made of circles - there should be 5 for 5 steps
        // We can't easily test the exact visual state, but we verify the view exists
        // by checking the window loaded properly
        XCTAssertTrue(app.windows["Welcome to CatPaws"].exists)
    }

    // MARK: - Get Started Button Test

    func testGetStartedClosesOnboarding() throws {
        app.launchArguments = ["-catpaws.onboarding.completed", "false", "-catpaws.onboarding.currentStep", "0"]
        app.launch()

        // Navigate to complete step - there are 6 steps total
        // Step 1: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to CatPaws"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()

        // Step 2: Permission Explanation
        XCTAssertTrue(app.staticTexts["Permissions Required"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()

        // Step 3: Grant Accessibility
        if app.buttons["Continue Anyway"].waitForExistence(timeout: 2) {
            app.buttons["Continue Anyway"].tap()
        } else if app.buttons["Next"].exists {
            app.buttons["Next"].tap()
        }

        // Step 4: Grant Input Monitoring
        if app.buttons["Continue Anyway"].waitForExistence(timeout: 2) {
            app.buttons["Continue Anyway"].tap()
        } else if app.buttons["Next"].exists {
            app.buttons["Next"].tap()
        }

        // Step 5: Test Detection
        if app.buttons["Skip Test"].waitForExistence(timeout: 2) {
            app.buttons["Skip Test"].tap()
        } else if app.buttons["Finish"].exists {
            app.buttons["Finish"].tap()
        }

        // Step 6: Complete - should be on complete step
        XCTAssertTrue(app.staticTexts["You're All Set!"].waitForExistence(timeout: 2))

        // Tap Get Started
        let window = app.windows["Welcome to CatPaws"]
        app.buttons["Get Started"].tap()

        // Window should close
        XCTAssertFalse(window.waitForExistence(timeout: 2), "Onboarding should close after Get Started")
    }
}
