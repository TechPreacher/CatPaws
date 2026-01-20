//
//  OnboardingStateTests.swift
//  CatPawsTests
//
//  Created on 2026-01-18.
//

import XCTest
@testable import CatPaws

final class OnboardingStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset onboarding state before each test
        OnboardingState.resetForTesting()
        // Also reset migration flag for migration tests
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")
    }

    override func tearDown() {
        // Clean up after each test
        OnboardingState.resetForTesting()
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")
        super.tearDown()
    }

    // MARK: - OnboardingStep Tests

    func testOnboardingStepOrder() {
        XCTAssertEqual(OnboardingStep.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingStep.permissionExplanation.rawValue, 1)
        XCTAssertEqual(OnboardingStep.grantAccessibility.rawValue, 2)
        XCTAssertEqual(OnboardingStep.grantInputMonitoring.rawValue, 3)
        XCTAssertEqual(OnboardingStep.testDetection.rawValue, 4)
        XCTAssertEqual(OnboardingStep.complete.rawValue, 5)
    }

    func testOnboardingStepCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 6)
    }

    func testOnboardingStepNext() {
        XCTAssertEqual(OnboardingStep.welcome.next, .permissionExplanation)
        XCTAssertEqual(OnboardingStep.permissionExplanation.next, .grantAccessibility)
        XCTAssertEqual(OnboardingStep.grantAccessibility.next, .grantInputMonitoring)
        XCTAssertEqual(OnboardingStep.grantInputMonitoring.next, .testDetection)
        XCTAssertEqual(OnboardingStep.testDetection.next, .complete)
        XCTAssertNil(OnboardingStep.complete.next)
    }

    func testOnboardingStepPrevious() {
        XCTAssertNil(OnboardingStep.welcome.previous)
        XCTAssertEqual(OnboardingStep.permissionExplanation.previous, .welcome)
        XCTAssertEqual(OnboardingStep.grantAccessibility.previous, .permissionExplanation)
        XCTAssertEqual(OnboardingStep.grantInputMonitoring.previous, .grantAccessibility)
        XCTAssertEqual(OnboardingStep.testDetection.previous, .grantInputMonitoring)
        XCTAssertEqual(OnboardingStep.complete.previous, .testDetection)
    }

    func testOnboardingStepIsFinal() {
        XCTAssertFalse(OnboardingStep.welcome.isFinal)
        XCTAssertFalse(OnboardingStep.permissionExplanation.isFinal)
        XCTAssertFalse(OnboardingStep.grantAccessibility.isFinal)
        XCTAssertFalse(OnboardingStep.grantInputMonitoring.isFinal)
        XCTAssertFalse(OnboardingStep.testDetection.isFinal)
        XCTAssertTrue(OnboardingStep.complete.isFinal)
    }

    func testOnboardingStepIsPermissionStep() {
        XCTAssertFalse(OnboardingStep.welcome.isPermissionStep)
        XCTAssertFalse(OnboardingStep.permissionExplanation.isPermissionStep)
        XCTAssertTrue(OnboardingStep.grantAccessibility.isPermissionStep)
        XCTAssertTrue(OnboardingStep.grantInputMonitoring.isPermissionStep)
        XCTAssertFalse(OnboardingStep.testDetection.isPermissionStep)
        XCTAssertFalse(OnboardingStep.complete.isPermissionStep)
    }

    // MARK: - OnboardingState Persistence Tests

    func testInitialStateIsNotCompleted() {
        let state = OnboardingState()
        XCTAssertFalse(state.hasCompletedOnboarding)
        XCTAssertFalse(state.wasSkipped)
    }

    func testCompleteMarksAsCompleted() {
        var state = OnboardingState()
        state.complete()

        XCTAssertTrue(state.hasCompletedOnboarding)
        XCTAssertFalse(state.wasSkipped)

        // Verify persistence
        let newState = OnboardingState()
        XCTAssertTrue(newState.hasCompletedOnboarding)
    }

    func testSkipMarksAsCompletedAndSkipped() {
        var state = OnboardingState()
        state.skip()

        XCTAssertTrue(state.hasCompletedOnboarding)
        XCTAssertTrue(state.wasSkipped)

        // Verify persistence
        let newState = OnboardingState()
        XCTAssertTrue(newState.hasCompletedOnboarding)
        XCTAssertTrue(newState.wasSkipped)
    }

    // MARK: - OnboardingState Navigation Tests

    func testInitialStepIsWelcome() {
        let state = OnboardingState()
        XCTAssertEqual(state.currentStep, .welcome)
    }

    func testAdvanceMovesToNextStep() {
        var state = OnboardingState()
        XCTAssertEqual(state.currentStep, .welcome)

        XCTAssertTrue(state.advance())
        XCTAssertEqual(state.currentStep, .permissionExplanation)

        XCTAssertTrue(state.advance())
        XCTAssertEqual(state.currentStep, .grantAccessibility)

        XCTAssertTrue(state.advance())
        XCTAssertEqual(state.currentStep, .grantInputMonitoring)

        XCTAssertTrue(state.advance())
        XCTAssertEqual(state.currentStep, .testDetection)

        XCTAssertTrue(state.advance())
        XCTAssertEqual(state.currentStep, .complete)

        // Can't advance past complete
        XCTAssertFalse(state.advance())
        XCTAssertEqual(state.currentStep, .complete)
    }

    func testGoBackMovesToPreviousStep() {
        var state = OnboardingState()
        state.currentStep = .testDetection

        XCTAssertTrue(state.goBack())
        XCTAssertEqual(state.currentStep, .grantInputMonitoring)

        XCTAssertTrue(state.goBack())
        XCTAssertEqual(state.currentStep, .grantAccessibility)

        XCTAssertTrue(state.goBack())
        XCTAssertEqual(state.currentStep, .permissionExplanation)

        XCTAssertTrue(state.goBack())
        XCTAssertEqual(state.currentStep, .welcome)

        // Can't go back past welcome
        XCTAssertFalse(state.goBack())
        XCTAssertEqual(state.currentStep, .welcome)
    }

    // MARK: - Reset Tests

    func testResetForTesting() {
        var state = OnboardingState()
        state.complete()

        XCTAssertTrue(state.hasCompletedOnboarding)

        OnboardingState.resetForTesting()

        let newState = OnboardingState()
        XCTAssertFalse(newState.hasCompletedOnboarding)
        XCTAssertFalse(newState.wasSkipped)
    }

    func testResetClearsOnboardingState() {
        var state = OnboardingState()
        state.complete()
        state.currentStep = .testDetection

        XCTAssertTrue(state.hasCompletedOnboarding)

        state.reset()

        // Create new instance to read from UserDefaults
        let newState = OnboardingState()
        XCTAssertFalse(newState.hasCompletedOnboarding)
        XCTAssertFalse(newState.wasSkipped)
        XCTAssertEqual(newState.currentStep, .welcome)
    }

    // MARK: - Migration Tests

    func testMigrateIfNeededIncrementsStepForUsersOnOldStep2() {
        // Simulate a user who was on old step 2 (grantPermission) before migration
        UserDefaults.standard.set(2, forKey: "catpaws.onboarding.currentStep")
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")

        OnboardingState.migrateIfNeeded()

        // Should now be step 3 (grantInputMonitoring)
        let migratedRawValue = UserDefaults.standard.integer(forKey: "catpaws.onboarding.currentStep")
        XCTAssertEqual(migratedRawValue, 3)
    }

    func testMigrateIfNeededIncrementsStepForUsersOnOldStep3() {
        // Simulate a user who was on old step 3 (testDetection) before migration
        UserDefaults.standard.set(3, forKey: "catpaws.onboarding.currentStep")
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")

        OnboardingState.migrateIfNeeded()

        // Should now be step 4 (testDetection in new scheme)
        let migratedRawValue = UserDefaults.standard.integer(forKey: "catpaws.onboarding.currentStep")
        XCTAssertEqual(migratedRawValue, 4)
    }

    func testMigrateIfNeededDoesNotChangeStepForUsersOnStep0Or1() {
        // Simulate a user who was on step 0 or 1 (welcome or permissionExplanation)
        UserDefaults.standard.set(1, forKey: "catpaws.onboarding.currentStep")
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")

        OnboardingState.migrateIfNeeded()

        // Should still be step 1
        let migratedRawValue = UserDefaults.standard.integer(forKey: "catpaws.onboarding.currentStep")
        XCTAssertEqual(migratedRawValue, 1)
    }

    func testMigrateIfNeededOnlyRunsOnce() {
        UserDefaults.standard.set(2, forKey: "catpaws.onboarding.currentStep")
        UserDefaults.standard.removeObject(forKey: "catpaws.onboarding.v2Migration")

        // First migration
        OnboardingState.migrateIfNeeded()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "catpaws.onboarding.currentStep"), 3)

        // Second migration attempt - should not change anything
        OnboardingState.migrateIfNeeded()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "catpaws.onboarding.currentStep"), 3)
    }
}
