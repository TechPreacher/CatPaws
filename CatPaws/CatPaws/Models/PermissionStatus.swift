//
//  PermissionStatus.swift
//  CatPaws
//
//  Created on 2026-01-19.
//

import Foundation

/// Represents the current state of a single system permission
struct PermissionStatus: Equatable {
    /// The type of permission
    let type: PermissionType

    /// Whether the permission is currently granted
    let isGranted: Bool

    /// Convenience accessor for the human-readable display name
    var displayName: String {
        type.displayName
    }

    /// Status text for UI display
    var statusText: String {
        isGranted ? "OK" : "Needs Permission"
    }

    /// URL to open System Settings for this permission
    var settingsURL: URL {
        type.settingsURL
    }
}

/// Observable state tracking both permissions required by CatPaws
@Observable
final class PermissionState {
    /// Current status of Accessibility permission
    var accessibility: PermissionStatus

    /// Current status of Input Monitoring permission
    var inputMonitoring: PermissionStatus

    /// Creates a new permission state with the given statuses
    init(
        accessibility: PermissionStatus = PermissionStatus(type: .accessibility, isGranted: false),
        inputMonitoring: PermissionStatus = PermissionStatus(type: .inputMonitoring, isGranted: false)
    ) {
        self.accessibility = accessibility
        self.inputMonitoring = inputMonitoring
    }

    /// True if both permissions are granted
    var allGranted: Bool {
        accessibility.isGranted && inputMonitoring.isGranted
    }

    /// True if either permission is missing
    var anyMissing: Bool {
        !allGranted
    }

    /// True if only Accessibility is missing
    var onlyAccessibilityMissing: Bool {
        !accessibility.isGranted && inputMonitoring.isGranted
    }

    /// True if only Input Monitoring is missing
    var onlyInputMonitoringMissing: Bool {
        accessibility.isGranted && !inputMonitoring.isGranted
    }

    /// Updates the state with new permission checks
    func update(accessibilityGranted: Bool, inputMonitoringGranted: Bool) {
        accessibility = PermissionStatus(type: .accessibility, isGranted: accessibilityGranted)
        inputMonitoring = PermissionStatus(type: .inputMonitoring, isGranted: inputMonitoringGranted)
    }
}
