//
//  OnboardingViewModel.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import ApplicationServices
import Combine
import CoreGraphics
import Foundation

/// View model for managing the first-run onboarding flow
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published private(set) var hasAccessibility: Bool = false
    @Published private(set) var hasInputMonitoring: Bool = false
    @Published private(set) var detectionTriggered: Bool = false

    /// Legacy compatibility - returns true if Input Monitoring is granted
    var hasPermission: Bool { hasInputMonitoring }

    // MARK: - Callbacks

    /// Called when onboarding is completed (either finished or skipped)
    var onComplete: (() -> Void)?

    // MARK: - Private

    private var onboardingState = OnboardingState()
    private var accessibilityPollingTimer: Timer?
    private var inputMonitoringPollingTimer: Timer?
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
        // Check initial permission status
        hasAccessibility = AXIsProcessTrusted()
        // Accessibility permission includes Input Monitoring capabilities
        hasInputMonitoring = hasAccessibility || Self.checkInputMonitoringPermission()

        // Restore persisted step
        let restoredStep = onboardingState.currentStep

        // Smart step restoration based on current permissions
        switch restoredStep {
        case .grantAccessibility where hasAccessibility:
            // Accessibility granted - skip Input Monitoring (it's included)
            currentStep = .testDetection
            onboardingState.currentStep = .testDetection
        case .grantInputMonitoring where hasInputMonitoring:
            // Input Monitoring granted - move to test detection
            currentStep = .testDetection
            onboardingState.currentStep = .testDetection
        default:
            currentStep = restoredStep
        }

        // Start permission polling if on a permission step
        if currentStep == .grantAccessibility && !hasAccessibility {
            startAccessibilityPolling()
        } else if currentStep == .grantInputMonitoring && !hasInputMonitoring {
            requestInputMonitoringPermission()
            startInputMonitoringPolling()
        }

        // Start keyboard monitoring if on test detection step
        if currentStep == .testDetection && hasInputMonitoring {
            startTestMonitoring()
        }
    }

    deinit {
        accessibilityPollingTimer?.invalidate()
        inputMonitoringPollingTimer?.invalidate()
        // Stop monitoring directly since we can't call MainActor methods from deinit
        keyboardMonitor.stopMonitoring()
        keyboardMonitor.delegate = nil
    }

    // MARK: - Navigation

    /// Move to the next step in the onboarding flow
    func nextStep() {
        guard var next = currentStep.next else {
            completeOnboarding()
            return
        }

        // Handle leaving current step
        switch currentStep {
        case .grantAccessibility:
            stopAccessibilityPolling()
            // Update hasInputMonitoring since Accessibility includes it
            if hasAccessibility {
                hasInputMonitoring = true
            }
        case .grantInputMonitoring:
            stopInputMonitoringPolling()
        case .testDetection:
            stopTestMonitoring()
        default:
            break
        }

        // Skip Input Monitoring step if Accessibility is granted (it's included)
        if next == .grantInputMonitoring && hasAccessibility {
            next = .testDetection
        }

        currentStep = next
        onboardingState.currentStep = next

        // Handle entering new step
        switch currentStep {
        case .grantAccessibility where !hasAccessibility:
            startAccessibilityPolling()
        case .grantInputMonitoring where !hasInputMonitoring:
            requestInputMonitoringPermission()
            startInputMonitoringPolling()
        case .testDetection where hasInputMonitoring:
            startTestMonitoring()
        default:
            break
        }
    }

    /// Move to the previous step in the onboarding flow
    func previousStep() {
        guard let previous = currentStep.previous else { return }

        // Handle leaving current step
        switch currentStep {
        case .grantAccessibility:
            stopAccessibilityPolling()
        case .grantInputMonitoring:
            stopInputMonitoringPolling()
        case .testDetection:
            stopTestMonitoring()
        default:
            break
        }

        currentStep = previous
        onboardingState.currentStep = previous

        // Handle entering previous step
        switch currentStep {
        case .grantAccessibility where !hasAccessibility:
            startAccessibilityPolling()
        case .grantInputMonitoring where !hasInputMonitoring:
            requestInputMonitoringPermission()
            startInputMonitoringPolling()
        default:
            break
        }
    }

    /// Skip the onboarding entirely
    func skip() {
        stopAccessibilityPolling()
        stopInputMonitoringPolling()
        stopTestMonitoring()
        onboardingState.skip()
        onComplete?()
    }

    // MARK: - Permission

    /// Open System Settings to grant Accessibility permission
    func openAccessibilitySettings() {
        PermissionService.shared.openSettings(for: .accessibility)
    }

    /// Open System Settings to grant Input Monitoring permission
    func openInputMonitoringSettings() {
        // Request permission to ensure CatPaws appears in Input Monitoring list
        requestInputMonitoringPermission()
        PermissionService.shared.openSettings(for: .inputMonitoring)
    }

    /// Legacy compatibility - opens Input Monitoring settings
    func openPermissionSettings() {
        openInputMonitoringSettings()
    }

    /// Request Input Monitoring permission to register app in system preferences
    /// This triggers the app to appear in the Input Monitoring list
    func requestInputMonitoringPermission() {
        CGRequestListenEventAccess()
    }

    /// Check if Input Monitoring permission is granted
    func checkPermission() -> Bool {
        hasInputMonitoring = Self.checkInputMonitoringPermission()
        return hasInputMonitoring
    }

    /// Check if Accessibility permission is granted
    func checkAccessibilityPermission() -> Bool {
        hasAccessibility = AXIsProcessTrusted()
        return hasAccessibility
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
        stopAccessibilityPolling()
        stopInputMonitoringPolling()
        stopTestMonitoring()
        onboardingState.complete()
        onComplete?()
    }

    // MARK: - Accessibility Polling

    private func startAccessibilityPolling() {
        guard accessibilityPollingTimer == nil else { return }

        accessibilityPollingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.permissionPollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pollAccessibilityStatus()
            }
        }
    }

    private func stopAccessibilityPolling() {
        accessibilityPollingTimer?.invalidate()
        accessibilityPollingTimer = nil
    }

    private func pollAccessibilityStatus() {
        let newStatus = AXIsProcessTrusted()
        if newStatus != hasAccessibility {
            hasAccessibility = newStatus
            // Accessibility includes Input Monitoring capability
            if hasAccessibility {
                hasInputMonitoring = true
            }
        }
    }

    // MARK: - Input Monitoring Polling

    private func startInputMonitoringPolling() {
        guard inputMonitoringPollingTimer == nil else { return }

        inputMonitoringPollingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.permissionPollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pollInputMonitoringStatus()
            }
        }
    }

    private func stopInputMonitoringPolling() {
        inputMonitoringPollingTimer?.invalidate()
        inputMonitoringPollingTimer = nil
    }

    private func pollInputMonitoringStatus() {
        let newStatus = Self.checkInputMonitoringPermission()
        if newStatus != hasInputMonitoring {
            hasInputMonitoring = newStatus
        }
    }

    /// Reliably check Input Monitoring permission by attempting to create an event tap
    /// CGPreflightListenEventAccess() is unreliable and can return true before permission is granted
    private static func checkInputMonitoringPermission() -> Bool {
        let eventMask: CGEventMask = 1 << CGEventType.keyDown.rawValue

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) else {
            return false
        }

        // Clean up the test tap immediately
        CFMachPortInvalidate(tap)
        return true
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
