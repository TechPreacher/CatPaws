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
    case microphone

    /// Human-readable name for the permission
    var displayName: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .inputMonitoring:
            return "Input Monitoring"
        case .microphone:
            return "Microphone"
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
        case .microphone:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        }
    }

    /// Description explaining why this permission is needed
    var explanation: String {
        switch self {
        case .accessibility:
            return "Required to detect keyboard patterns and identify when your cat is on the keyboard."
        case .inputMonitoring:
            return "Required to monitor keyboard input and temporarily block keys when cat activity is detected."
        case .microphone:
            return "Required to detect cat purring sounds and protect your keyboard before your cat reaches it."
        }
    }
}
