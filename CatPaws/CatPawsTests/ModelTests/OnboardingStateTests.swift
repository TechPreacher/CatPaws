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
    }

    override func tearDown() {
        // Clean up after each test
        OnboardingState.resetForTesting()
        super.tearDown()
    }

    // MARK: - OnboardingStep Tests

    func testOnboardingStepOrder() {
        XCTAssertEqual(OnboardingStep.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingStep.permissionExplanation.rawValue, 1)
        XCTAssertEqual(OnboardingStep.grantPermission.rawValue, 2)
        XCTAssertEqual(OnboardingStep.testDetection.rawValue, 3)
        XCTAssertEqual(OnboardingStep.complete.rawValue, 4)
    }

    func testOnboardingStepNext() {
        XCTAssertEqual(OnboardingStep.welcome.next, .permissionExplanation)
        XCTAssertEqual(OnboardingStep.permissionExplanation.next, .grantPermission)
        XCTAssertEqual(OnboardingStep.grantPermission.next, .testDetection)
        XCTAssertEqual(OnboardingStep.testDetection.next, .complete)
        XCTAssertNil(OnboardingStep.complete.next)
    }

    func testOnboardingStepPrevious() {
        XCTAssertNil(OnboardingStep.welcome.previous)
        XCTAssertEqual(OnboardingStep.permissionExplanation.previous, .welcome)
        XCTAssertEqual(OnboardingStep.grantPermission.previous, .permissionExplanation)
        XCTAssertEqual(OnboardingStep.testDetection.previous, .grantPermission)
        XCTAssertEqual(OnboardingStep.complete.previous, .testDetection)
    }

    func testOnboardingStepIsFinal() {
        XCTAssertFalse(OnboardingStep.welcome.isFinal)
        XCTAssertFalse(OnboardingStep.permissionExplanation.isFinal)
        XCTAssertFalse(OnboardingStep.grantPermission.isFinal)
        XCTAssertFalse(OnboardingStep.testDetection.isFinal)
        XCTAssertTrue(OnboardingStep.complete.isFinal)
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
        XCTAssertEqual(state.currentStep, .grantPermission)

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
        XCTAssertEqual(state.currentStep, .grantPermission)

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
}
