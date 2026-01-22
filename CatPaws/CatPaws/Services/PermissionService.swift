//
//  PermissionService.swift
//  CatPaws
//
//  Created on 2026-01-19.
//

import AppKit
import ApplicationServices
import AVFoundation
import Combine
import CoreGraphics
import Foundation

/// Protocol for checking system permissions
@MainActor
protocol PermissionChecking {
    /// Check if Accessibility permission is granted
    /// - Returns: true if the process is trusted for Accessibility
    func checkAccessibility() -> Bool

    /// Check if Input Monitoring permission is granted
    /// - Returns: true if the process can listen to events
    func checkInputMonitoring() -> Bool

    /// Check if Microphone permission is granted
    /// - Returns: true if the process has microphone access
    func checkMicrophone() -> Bool

    /// Request microphone permission asynchronously
    /// - Returns: true if permission was granted
    func requestMicrophonePermission() async -> Bool

    /// Get current status of both permissions
    /// - Returns: PermissionState with both statuses
    func getCurrentState() -> PermissionState

    /// Open System Settings to the appropriate pane
    /// - Parameter type: The permission type to open settings for
    func openSettings(for type: PermissionType)
}

/// Concrete implementation of permission checking using macOS APIs
@MainActor
final class PermissionService: PermissionChecking, ObservableObject {
    // MARK: - Singleton

    /// Shared instance for app-wide access
    static let shared = PermissionService()

    // MARK: - Published State

    /// Current state of both permissions (published for UI binding)
    @Published private(set) var state: PermissionState

    // MARK: - Polling

    /// Timer for polling permission status
    private var pollingTimer: Timer?

    /// Polling interval in seconds
    static let pollingInterval: TimeInterval = 1.0

    /// Callback invoked when permission state changes
    var onStateChange: ((PermissionState) -> Void)?

    /// Previous state for change detection
    private var previousState: (accessibility: Bool, inputMonitoring: Bool)?

    // MARK: - Initialization

    init() {
        self.state = PermissionState()
        // Perform initial check
        _ = getCurrentState()
    }

    deinit {
        pollingTimer?.invalidate()
    }

    // MARK: - PermissionChecking

    /// Check if Accessibility permission is granted using AXIsProcessTrusted()
    /// - Returns: true if the process is trusted for Accessibility
    func checkAccessibility() -> Bool {
        AXIsProcessTrusted()
    }

    /// Check if Input Monitoring permission is granted
    /// Note: Accessibility permission includes Input Monitoring capabilities
    /// - Returns: true if the process can listen to events
    func checkInputMonitoring() -> Bool {
        // Accessibility permission is a superset that includes Input Monitoring
        if AXIsProcessTrusted() {
            return true
        }

        // Fall back to event tap test for standalone Input Monitoring permission
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

    /// Check if Microphone permission is granted
    /// - Returns: true if the process has microphone access
    func checkMicrophone() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    /// Request microphone permission asynchronously
    /// - Returns: true if permission was granted
    func requestMicrophonePermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    /// Get current snapshot of both permission statuses
    /// - Returns: PermissionState with both statuses updated
    @discardableResult
    func getCurrentState() -> PermissionState {
        let accessibilityGranted = checkAccessibility()
        let inputMonitoringGranted = checkInputMonitoring()

        state.update(
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted
        )

        return state
    }

    /// Open System Settings to the appropriate pane for the given permission type
    /// - Parameter type: The permission type to open settings for
    func openSettings(for type: PermissionType) {
        NSWorkspace.shared.open(type.settingsURL)
    }

    // MARK: - Polling

    /// Start polling for permission status changes at 1-second intervals
    func startPolling() {
        guard pollingTimer == nil else { return }

        // Store initial state for change detection
        previousState = (checkAccessibility(), checkInputMonitoring())

        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pollPermissionStatus()
            }
        }
    }

    /// Stop polling for permission status changes
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        previousState = nil
    }

    /// Check if polling is currently active
    var isPolling: Bool {
        pollingTimer != nil
    }

    // MARK: - Private

    /// Poll current permission status and notify if changed
    private func pollPermissionStatus() {
        let currentAccessibility = checkAccessibility()
        let currentInputMonitoring = checkInputMonitoring()

        // Update state
        state.update(
            accessibilityGranted: currentAccessibility,
            inputMonitoringGranted: currentInputMonitoring
        )

        // Check for changes
        if let previous = previousState {
            let changed = (previous.accessibility != currentAccessibility) ||
                          (previous.inputMonitoring != currentInputMonitoring)

            if changed {
                onStateChange?(state)
            }
        }

        // Store current as previous for next poll
        previousState = (currentAccessibility, currentInputMonitoring)
    }
}
