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

    /// Create a new app state with default values
    init(isActive: Bool = false) {
        self.isActive = isActive
    }
}
