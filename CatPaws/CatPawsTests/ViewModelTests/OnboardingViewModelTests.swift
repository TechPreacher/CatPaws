//
//  OnboardingViewModelTests.swift
//  CatPawsTests
//
//  Created on 2026-01-18.
//

import XCTest
@testable import CatPaws

@MainActor
final class OnboardingViewModelTests: XCTestCase {
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

    // MARK: - Initialization Tests

    func testInitialState() {
        let viewModel = OnboardingViewModel()

        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.detectionTriggered)
    }

    // MARK: - Navigation Tests

    func testNextStepAdvancesFromWelcome() {
        let viewModel = OnboardingViewModel()
        XCTAssertEqual(viewModel.currentStep, .welcome)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .permissionExplanation)
    }

    func testNextStepAdvancesThroughAllSteps() {
        let viewModel = OnboardingViewModel()

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .permissionExplanation)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .grantPermission)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .testDetection)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .complete)
    }

    func testPreviousStepGoesBack() {
        let viewModel = OnboardingViewModel()

        // Advance to grantPermission
        viewModel.nextStep()
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .grantPermission)

        // Go back
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .permissionExplanation)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testPreviousStepDoesNothingAtWelcome() {
        let viewModel = OnboardingViewModel()
        XCTAssertEqual(viewModel.currentStep, .welcome)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    // MARK: - Completion Tests

    func testNextStepFromCompleteCallsOnComplete() {
        let viewModel = OnboardingViewModel()
        var completionCalled = false
        viewModel.onComplete = {
            completionCalled = true
        }

        // Navigate to complete step
        viewModel.nextStep() // -> permissionExplanation
        viewModel.nextStep() // -> grantPermission
        viewModel.nextStep() // -> testDetection
        viewModel.nextStep() // -> complete

        XCTAssertEqual(viewModel.currentStep, .complete)
        XCTAssertFalse(completionCalled)

        // Next from complete should call onComplete
        viewModel.nextStep()
        XCTAssertTrue(completionCalled)
    }

    func testCompletionPersistsState() {
        let viewModel = OnboardingViewModel()
        viewModel.onComplete = {}

        // Navigate through all steps and complete
        viewModel.nextStep()
        viewModel.nextStep()
        viewModel.nextStep()
        viewModel.nextStep()
        viewModel.nextStep() // This triggers completion

        // Verify state was persisted
        let state = OnboardingState()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }

    // MARK: - Skip Tests

    func testSkipCallsOnComplete() {
        let viewModel = OnboardingViewModel()
        var completionCalled = false
        viewModel.onComplete = {
            completionCalled = true
        }

        viewModel.skip()
        XCTAssertTrue(completionCalled)
    }

    func testSkipPersistsState() {
        let viewModel = OnboardingViewModel()
        viewModel.onComplete = {}

        viewModel.skip()

        // Verify state was persisted
        let state = OnboardingState()
        XCTAssertTrue(state.hasCompletedOnboarding)
        XCTAssertTrue(state.wasSkipped)
    }

    func testSkipFromAnyStep() {
        let viewModel = OnboardingViewModel()
        var completionCalled = false
        viewModel.onComplete = {
            completionCalled = true
        }

        // Advance to middle step
        viewModel.nextStep()
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .grantPermission)

        // Skip should still work
        viewModel.skip()
        XCTAssertTrue(completionCalled)
    }

    // MARK: - Detection Test Step Tests

    func testDetectionDidTrigger() {
        let viewModel = OnboardingViewModel()
        XCTAssertFalse(viewModel.detectionTriggered)

        viewModel.detectionDidTrigger()
        XCTAssertTrue(viewModel.detectionTriggered)
    }

    func testResetDetectionTest() {
        let viewModel = OnboardingViewModel()

        viewModel.detectionDidTrigger()
        XCTAssertTrue(viewModel.detectionTriggered)

        viewModel.resetDetectionTest()
        XCTAssertFalse(viewModel.detectionTriggered)
    }

    // MARK: - Permission Tests

    func testCheckPermissionReturnsCurrentStatus() {
        let viewModel = OnboardingViewModel()

        // This will return the actual system permission status
        // We can't control the system permission in tests, but we can verify the method works
        let result = viewModel.checkPermission()
        XCTAssertEqual(result, viewModel.hasPermission)
    }
}
