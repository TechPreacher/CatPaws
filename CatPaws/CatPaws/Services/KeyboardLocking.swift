//
//  KeyboardLocking.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Protocol for keyboard lock services
protocol KeyboardLocking: AnyObject {
    /// Whether the keyboard is currently locked
    var isLocked: Bool { get }

    /// Lock the keyboard, blocking all input
    func lock()

    /// Unlock the keyboard, allowing input
    func unlock()
}
