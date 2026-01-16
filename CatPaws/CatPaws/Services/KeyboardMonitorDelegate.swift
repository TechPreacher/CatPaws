//
//  KeyboardMonitorDelegate.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Delegate protocol for receiving keyboard events from KeyboardMonitor
protocol KeyboardMonitorDelegate: AnyObject {
    /// Called when a key is pressed
    /// - Parameters:
    ///   - keyCode: The CGKeyCode of the pressed key
    ///   - timestamp: When the event occurred
    func keyDidPress(_ keyCode: UInt16, at timestamp: Date)

    /// Called when a key is released
    /// - Parameters:
    ///   - keyCode: The CGKeyCode of the released key
    ///   - timestamp: When the event occurred
    func keyDidRelease(_ keyCode: UInt16, at timestamp: Date)

    /// Called when modifier flags change
    /// - Parameters:
    ///   - modifiers: Set of currently active modifier key codes
    ///   - timestamp: When the event occurred
    func modifiersDidChange(_ modifiers: Set<UInt16>, at timestamp: Date)
}
