//
//  KeyboardLockService.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Service responsible for blocking keyboard input when locked
final class KeyboardLockService: KeyboardLocking {
    // MARK: - Properties

    private(set) var isLocked: Bool = false

    // MARK: - KeyboardLocking

    func lock() {
        isLocked = true
    }

    func unlock() {
        isLocked = false
    }

    // MARK: - Event Blocking

    /// Check if an event should be blocked
    /// - Returns: true if events should be blocked (keyboard is locked)
    func shouldBlockEvent() -> Bool {
        isLocked
    }
}
