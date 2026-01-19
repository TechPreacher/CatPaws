//
//  OnboardingViewModel.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation
import Combine
import CoreGraphics

/// View model for managing the first-run onboarding flow
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published private(set) var hasPermission: Bool = false
    @Published private(set) var detectionTriggered: Bool = false

    // MARK: - Callbacks

    /// Called when onboarding is completed (either finished or skipped)
    var onComplete: (() -> Void)?

    // MARK: - Private

    private var onboardingState = OnboardingState()
    private var permissionPollingTimer: Timer?
    private static let permissionPollingInterval: TimeInterval = 1.0

    // MARK: - Test Detection

    /// Key codes for S, E, D test pattern
    private static let testKeyS: UInt16 = 1   // S key
    private static let testKeyE: UInt16 = 14  // E key
    private static let testKeyD: UInt16 = 2   // D key

    /// Currently pressed keys during test
    private var pressedKeys: Set<UInt16> = []

    /// Reference to keyboard monitor for test detection
    private let keyboardMonitor = KeyboardMonitor.shared

    // MARK: - Initialization

    init() {
        hasPermission = CGPreflightListenEventAccess()

        // Restore persisted step
        let restoredStep = onboardingState.currentStep

        // If permission is already granted and we were on the grant permission step,
        // skip ahead to test detection (user granted permission and restarted)
        if hasPermission && restoredStep == .grantPermission {
            currentStep = .testDetection
            onboardingState.currentStep = .testDetection
        } else {
            currentStep = restoredStep
        }

        // Start permission polling if on grant permission step without permission
        if currentStep == .grantPermission && !hasPermission {
            requestInputMonitoringPermission()
            startPermissionPolling()
        }

        // Start keyboard monitoring if on test detection step
        if currentStep == .testDetection && hasPermission {
            startTestMonitoring()
        }
    }

    deinit {
        permissionPollingTimer?.invalidate()
        // Stop monitoring directly since we can't call MainActor methods from deinit
        keyboardMonitor.stopMonitoring()
        keyboardMonitor.delegate = nil
    }

    // MARK: - Navigation

    /// Move to the next step in the onboarding flow
    func nextStep() {
        guard let next = currentStep.next else {
            completeOnboarding()
            return
        }

        // Handle leaving current step
        if currentStep == .grantPermission {
            stopPermissionPolling()
        } else if currentStep == .testDetection {
            stopTestMonitoring()
        }

        currentStep = next
        onboardingState.currentStep = next

        // Handle entering new step
        if currentStep == .grantPermission && !hasPermission {
            // Request permission to ensure CatPaws appears in Input Monitoring list
            requestInputMonitoringPermission()
            startPermissionPolling()
        } else if currentStep == .testDetection && hasPermission {
            startTestMonitoring()
        }
    }

    /// Move to the previous step in the onboarding flow
    func previousStep() {
        guard let previous = currentStep.previous else { return }

        // Handle leaving current step
        if currentStep == .grantPermission {
            stopPermissionPolling()
        } else if currentStep == .testDetection {
            stopTestMonitoring()
        }

        currentStep = previous
        onboardingState.currentStep = previous

        // Handle entering previous step
        if currentStep == .grantPermission && !hasPermission {
            requestInputMonitoringPermission()
            startPermissionPolling()
        }
    }

    /// Skip the onboarding entirely
    func skip() {
        stopPermissionPolling()
        stopTestMonitoring()
        onboardingState.skip()
        onComplete?()
    }

    // MARK: - Permission

    /// Open System Settings to grant Input Monitoring permission
    func openPermissionSettings() {
        // Request permission to ensure CatPaws appears in Input Monitoring list
        requestInputMonitoringPermission()
        PermissionGuideView.openInputMonitoringSettings()
    }

    /// Request Input Monitoring permission to register app in system preferences
    /// This triggers the app to appear in the Input Monitoring list
    func requestInputMonitoringPermission() {
        CGRequestListenEventAccess()
    }

    /// Check if Input Monitoring permission is granted
    func checkPermission() -> Bool {
        hasPermission = CGPreflightListenEventAccess()
        return hasPermission
    }

    // MARK: - Detection Test

    /// Called when a cat detection is triggered during the test step
    func detectionDidTrigger() {
        detectionTriggered = true
    }

    /// Reset the detection test state
    func resetDetectionTest() {
        detectionTriggered = false
    }

    // MARK: - Private Methods

    private func completeOnboarding() {
        stopPermissionPolling()
        stopTestMonitoring()
        onboardingState.complete()
        onComplete?()
    }

    private func startPermissionPolling() {
        guard permissionPollingTimer == nil else { return }

        permissionPollingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.permissionPollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pollPermissionStatus()
            }
        }
    }

    private func stopPermissionPolling() {
        permissionPollingTimer?.invalidate()
        permissionPollingTimer = nil
    }

    private func pollPermissionStatus() {
        let newStatus = CGPreflightListenEventAccess()
        if newStatus != hasPermission {
            hasPermission = newStatus
        }
    }

    // MARK: - Test Monitoring

    private func startTestMonitoring() {
        pressedKeys.removeAll()
        keyboardMonitor.delegate = self
        do {
            try keyboardMonitor.startMonitoring()
        } catch {
            // If monitoring fails, user can still skip the test
        }
    }

    private func stopTestMonitoring() {
        keyboardMonitor.stopMonitoring()
        keyboardMonitor.delegate = nil
        pressedKeys.removeAll()
    }

    private func checkForTestPattern() {
        // Check if S, E, D are all pressed
        let hasS = pressedKeys.contains(Self.testKeyS)
        let hasE = pressedKeys.contains(Self.testKeyE)
        let hasD = pressedKeys.contains(Self.testKeyD)

        if hasS && hasE && hasD {
            detectionTriggered = true
            stopTestMonitoring()
        }
    }
}

// MARK: - KeyboardMonitorDelegate

extension OnboardingViewModel: KeyboardMonitorDelegate {
    nonisolated func keyDidPress(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            pressedKeys.insert(keyCode)
            checkForTestPattern()
        }
    }

    nonisolated func keyDidRelease(_ keyCode: UInt16, at timestamp: Date) {
        Task { @MainActor in
            pressedKeys.remove(keyCode)
        }
    }

    nonisolated func modifiersDidChange(_ modifiers: Set<UInt16>, at timestamp: Date) {
        // Not needed for test detection
    }
}
