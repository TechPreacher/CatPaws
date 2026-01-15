//
//  AppState.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import Foundation

/// Represents the current state of the application
struct AppState {
    /// Whether the app functionality is currently active
    var isActive: Bool = false

    /// Last activity timestamp
    var lastActivityDate: Date?

    /// Create a new app state with default values
    init(isActive: Bool = false, lastActivityDate: Date? = nil) {
        self.isActive = isActive
        self.lastActivityDate = lastActivityDate
    }
}
