//
//  LockStateManaging.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Protocol for lock state management
protocol LockStateManaging: AnyObject {
    /// Current lock state
    var state: LockState { get }

    /// Called when a cat pattern is detected
    /// - Parameter detection: The detection event
    func handleDetection(_ detection: DetectionEvent)

    /// Called when keys are released (no longer pressed)
    func handleKeysReleased()

    /// Called to manually unlock the keyboard
    func manualUnlock()

    /// Called to check if keyboard should remain locked
    func performRecheck(pressedKeyCount: Int)
}
