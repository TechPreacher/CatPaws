//
//  OnboardingViewModel.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation
import ApplicationServices
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

    // MARK: - Initialization

    init() {
        hasPermission = AXIsProcessTrusted()
    }

    deinit {
        permissionPollingTimer?.invalidate()
    }

    // MARK: - Navigation

    /// Move to the next step in the onboarding flow
    func nextStep() {
        guard let next = currentStep.next else {
            completeOnboarding()
            return
        }

        // Handle step-specific logic
        if currentStep == .grantPermission {
            stopPermissionPolling()
        }

        currentStep = next

        // Start permission polling when entering grant permission step
        if currentStep == .grantPermission && !hasPermission {
            // Request permission to ensure CatPaws appears in Input Monitoring list
            requestInputMonitoringPermission()
            startPermissionPolling()
        }
    }

    /// Move to the previous step in the onboarding flow
    func previousStep() {
        guard let previous = currentStep.previous else { return }

        if currentStep == .grantPermission {
            stopPermissionPolling()
        }

        currentStep = previous
    }

    /// Skip the onboarding entirely
    func skip() {
        stopPermissionPolling()
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
        hasPermission = AXIsProcessTrusted()
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
        let newStatus = AXIsProcessTrusted()
        if newStatus != hasPermission {
            hasPermission = newStatus
        }
    }
}
