//
//  PermissionError.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Errors related to keyboard monitoring permissions
enum PermissionError: Error, LocalizedError {
    /// User has not granted accessibility/input monitoring permission
    case accessibilityNotGranted

    /// Failed to create CGEvent tap for keyboard monitoring
    case eventTapCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return """
                Input Monitoring permission is required. \
                Please enable it in System Settings > Privacy & Security > Input Monitoring.
                """
        case .eventTapCreationFailed:
            return "Failed to create keyboard event monitor. Please try restarting the application."
        }
    }
}
