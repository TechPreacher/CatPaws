//
//  PermissionType.swift
//  CatPaws
//
//  Created on 2026-01-19.
//

import Foundation

/// Represents the types of system permissions required by CatPaws
enum PermissionType: String, CaseIterable {
    case accessibility
    case inputMonitoring

    /// Human-readable name for the permission
    var displayName: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .inputMonitoring:
            return "Input Monitoring"
        }
    }

    /// URL to open the specific System Settings pane for this permission
    var settingsURL: URL {
        switch self {
        case .accessibility:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        case .inputMonitoring:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        }
    }

    /// Description explaining why this permission is needed
    var explanation: String {
        switch self {
        case .accessibility:
            return "Required to detect keyboard patterns and identify when your cat is on the keyboard."
        case .inputMonitoring:
            return "Required to monitor keyboard input and temporarily block keys when cat activity is detected."
        }
    }
}
