//
//  KeyboardState.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Tracks the current state of all pressed keys for pattern detection
struct KeyboardState {
    // MARK: - Properties

    /// Set of currently pressed key codes (CGKeyCode)
    private(set) var pressedKeys: Set<UInt16>

    /// Set of currently active modifier key codes
    private(set) var activeModifiers: Set<UInt16>

    /// Timestamp of most recent key event
    private(set) var lastKeyEventTime: Date

    // MARK: - Initialization

    init(
        pressedKeys: Set<UInt16> = [],
        activeModifiers: Set<UInt16> = [],
        lastKeyEventTime: Date = Date()
    ) {
        self.pressedKeys = pressedKeys
        self.activeModifiers = activeModifiers
        self.lastKeyEventTime = lastKeyEventTime
    }

    // MARK: - Computed Properties

    /// Returns pressed keys minus modifiers
    var nonModifierKeys: Set<UInt16> {
        return pressedKeys.subtracting(KeyboardAdjacencyMap.modifierKeyCodes)
    }

    /// Count of non-modifier keys currently pressed
    var pressedKeyCount: Int {
        return nonModifierKeys.count
    }

    /// True if only modifier keys are pressed (or no keys at all)
    var hasModifiersOnly: Bool {
        return nonModifierKeys.isEmpty
    }

    // MARK: - Mutation Methods

    /// Record a key press
    mutating func keyPressed(_ keyCode: UInt16) {
        pressedKeys.insert(keyCode)
        lastKeyEventTime = Date()
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
        lastKeyEventTime = Date()
    }
}
