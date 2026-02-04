//
//  KeyboardState.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Represents a single key press event with its timestamp for time window tracking
struct TimestampedKeyEvent: Equatable {
    /// The key code of the pressed key
    let keyCode: UInt16
    /// When the key was pressed
    let timestamp: Date
}

/// Tracks the current state of all pressed keys for pattern detection
struct KeyboardState {
    // MARK: - Properties

    /// Set of currently pressed key codes (CGKeyCode)
    private(set) var pressedKeys: Set<UInt16>

    /// Set of currently active modifier key codes
    private(set) var activeModifiers: Set<UInt16>

    /// Timestamp of most recent key event
    private(set) var lastKeyEventTime: Date

    /// Recent key presses within the time window for detecting rapid sequential presses
    private(set) var recentKeyPresses: [TimestampedKeyEvent]

    /// Duration of the rolling time window for key aggregation (in seconds)
    let timeWindowSeconds: TimeInterval

    // MARK: - Initialization

    init(
        pressedKeys: Set<UInt16> = [],
        activeModifiers: Set<UInt16> = [],
        lastKeyEventTime: Date = Date(),
        recentKeyPresses: [TimestampedKeyEvent] = [],
        timeWindowSeconds: TimeInterval = 0.3
    ) {
        self.pressedKeys = pressedKeys
        self.activeModifiers = activeModifiers
        self.lastKeyEventTime = lastKeyEventTime
        self.recentKeyPresses = recentKeyPresses
        self.timeWindowSeconds = timeWindowSeconds
    }

    // MARK: - Computed Properties

    /// Returns pressed keys minus modifiers
    var nonModifierKeys: Set<UInt16> {
        pressedKeys.subtracting(KeyboardAdjacencyMap.modifierKeyCodes)
    }

    /// Count of non-modifier keys currently pressed
    var pressedKeyCount: Int {
        nonModifierKeys.count
    }

    /// True if only modifier keys are pressed (or no keys at all)
    var hasModifiersOnly: Bool {
        nonModifierKeys.isEmpty
    }

    /// Returns unique key codes from recent key presses within the time window
    var keysInTimeWindow: Set<UInt16> {
        let now = Date()
        let cutoff = now.addingTimeInterval(-timeWindowSeconds)
        return Set(recentKeyPresses.filter { $0.timestamp >= cutoff }.map { $0.keyCode })
    }

    /// Returns keys for cat paw detection, excluding modifier keys.
    /// Only includes keys from the time window if multiple keys are currently held simultaneously,
    /// which distinguishes cat paws (simultaneous presses) from fast human typing (sequential presses).
    var keysForDetection: Set<UInt16> {
        let currentNonModifierKeys = pressedKeys.subtracting(KeyboardAdjacencyMap.modifierKeyCodes)

        // Only expand to time window if 2+ non-modifier keys are currently held down.
        // This prevents false positives from fast sequential typing where only 1 key
        // is pressed at a time, while still catching cat paws that press multiple keys.
        if currentNonModifierKeys.count >= 2 {
            let timeWindowNonModifierKeys = keysInTimeWindow.subtracting(KeyboardAdjacencyMap.modifierKeyCodes)
            return currentNonModifierKeys.union(timeWindowNonModifierKeys)
        } else {
            return currentNonModifierKeys
        }
    }

    // MARK: - Mutation Methods

    /// Record a key press with timestamp for time window tracking
    mutating func keyPressed(_ keyCode: UInt16, at timestamp: Date = Date()) {
        // Prune old entries outside the time window
        let cutoff = timestamp.addingTimeInterval(-timeWindowSeconds)
        recentKeyPresses.removeAll { $0.timestamp < cutoff }

        // Add new timestamped event (only for non-modifier keys)
        if !KeyboardAdjacencyMap.modifierKeyCodes.contains(keyCode) {
            recentKeyPresses.append(TimestampedKeyEvent(keyCode: keyCode, timestamp: timestamp))
        }

        pressedKeys.insert(keyCode)
        lastKeyEventTime = timestamp
    }

    /// Record a key release
    mutating func keyReleased(_ keyCode: UInt16) {
        pressedKeys.remove(keyCode)
        lastKeyEventTime = Date()
    }

    /// Record a modifier key press
    mutating func modifierPressed(_ keyCode: UInt16) {
        activeModifiers.insert(keyCode)
        pressedKeys.insert(keyCode)
        lastKeyEventTime = Date()
    }

    /// Record a modifier key release
    mutating func modifierReleased(_ keyCode: UInt16) {
        activeModifiers.remove(keyCode)
        pressedKeys.remove(keyCode)
        lastKeyEventTime = Date()
    }

    /// Update active modifiers from a set (for flags changed events)
    mutating func updateModifiers(_ modifiers: Set<UInt16>) {
        // Remove modifiers that are no longer active
        let releasedModifiers = activeModifiers.subtracting(modifiers)
        for modifier in releasedModifiers {
            modifierReleased(modifier)
        }

        // Add newly pressed modifiers
        let newModifiers = modifiers.subtracting(activeModifiers)
        for modifier in newModifiers {
            modifierPressed(modifier)
        }
    }

    /// Clear all key state
    mutating func clearAll() {
        pressedKeys.removeAll()
        activeModifiers.removeAll()
        recentKeyPresses.removeAll()
        lastKeyEventTime = Date()
    }
}
