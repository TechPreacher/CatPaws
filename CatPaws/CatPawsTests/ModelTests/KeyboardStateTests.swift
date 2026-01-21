//
//  KeyboardStateTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

final class KeyboardStateTests: XCTestCase {
    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let state = KeyboardState()
        XCTAssertTrue(state.pressedKeys.isEmpty)
        XCTAssertTrue(state.activeModifiers.isEmpty)
        XCTAssertNotNil(state.lastKeyEventTime)
    }

    func testCustomInitialization() {
        let date = Date()
        let pressedKeys: Set<UInt16> = [0x00, 0x01, 0x02]  // A, S, D
        let modifiers: Set<UInt16> = [0x37]  // Command

        let state = KeyboardState(
            pressedKeys: pressedKeys,
            activeModifiers: modifiers,
            lastKeyEventTime: date
        )

        XCTAssertEqual(state.pressedKeys, pressedKeys)
        XCTAssertEqual(state.activeModifiers, modifiers)
        XCTAssertEqual(state.lastKeyEventTime, date)
    }

    // MARK: - Computed Property Tests

    func testNonModifierKeys() {
        // A, S, D + Command modifier
        let state = KeyboardState(
            pressedKeys: [0x00, 0x01, 0x02, 0x37],
            activeModifiers: [0x37],
            lastKeyEventTime: Date()
        )

        let nonModifiers = state.nonModifierKeys
        XCTAssertEqual(nonModifiers.count, 3)
        XCTAssertTrue(nonModifiers.contains(0x00))  // A
        XCTAssertTrue(nonModifiers.contains(0x01))  // S
        XCTAssertTrue(nonModifiers.contains(0x02))  // D
        XCTAssertFalse(nonModifiers.contains(0x37)) // Command excluded
    }

    func testPressedKeyCount() {
        let state = KeyboardState(
            pressedKeys: [0x00, 0x01, 0x02, 0x37],  // A, S, D + Command
            activeModifiers: [0x37],
            lastKeyEventTime: Date()
        )

        // Should count only non-modifier keys
        XCTAssertEqual(state.pressedKeyCount, 3)
    }

    func testHasModifiersOnlyTrue() {
        let state = KeyboardState(
            pressedKeys: [0x37, 0x38],  // Command + Shift
            activeModifiers: [0x37, 0x38],
            lastKeyEventTime: Date()
        )

        XCTAssertTrue(state.hasModifiersOnly)
    }

    func testHasModifiersOnlyFalse() {
        let state = KeyboardState(
            pressedKeys: [0x00, 0x37],  // A + Command
            activeModifiers: [0x37],
            lastKeyEventTime: Date()
        )

        XCTAssertFalse(state.hasModifiersOnly)
    }

    func testHasModifiersOnlyWithNoKeys() {
        let state = KeyboardState()
        // No keys pressed at all should return true (no non-modifier keys)
        XCTAssertTrue(state.hasModifiersOnly)
    }

    // MARK: - Key Press/Release Tests

    func testKeyPress() {
        var state = KeyboardState()
        state.keyPressed(0x00)  // A
        XCTAssertTrue(state.pressedKeys.contains(0x00))
        XCTAssertEqual(state.pressedKeys.count, 1)
    }

    func testKeyRelease() {
        var state = KeyboardState(pressedKeys: [0x00, 0x01])
        state.keyReleased(0x00)  // Release A
        XCTAssertFalse(state.pressedKeys.contains(0x00))
        XCTAssertTrue(state.pressedKeys.contains(0x01))
    }

    func testModifierPress() {
        var state = KeyboardState()
        state.modifierPressed(0x37)  // Command
        XCTAssertTrue(state.activeModifiers.contains(0x37))
        XCTAssertTrue(state.pressedKeys.contains(0x37))
    }

    func testModifierRelease() {
        var state = KeyboardState(
            pressedKeys: [0x37],
            activeModifiers: [0x37]
        )
        state.modifierReleased(0x37)
        XCTAssertFalse(state.activeModifiers.contains(0x37))
        XCTAssertFalse(state.pressedKeys.contains(0x37))
    }

    func testClearAllKeys() {
        var state = KeyboardState(
            pressedKeys: [0x00, 0x01, 0x02, 0x37],
            activeModifiers: [0x37]
        )
        state.clearAll()
        XCTAssertTrue(state.pressedKeys.isEmpty)
        XCTAssertTrue(state.activeModifiers.isEmpty)
    }

    // MARK: - Time Window Tests

    func testKeysInTimeWindowReturnsCorrectKeys() {
        // Given: A KeyboardState with recent key presses within the time window
        let now = Date()
        let recentPresses = [
            TimestampedKeyEvent(keyCode: 0x00, timestamp: now.addingTimeInterval(-0.1)),  // A - 100ms ago
            TimestampedKeyEvent(keyCode: 0x01, timestamp: now.addingTimeInterval(-0.2)),  // S - 200ms ago
            TimestampedKeyEvent(keyCode: 0x02, timestamp: now.addingTimeInterval(-0.25))  // D - 250ms ago
        ]
        let state = KeyboardState(
            recentKeyPresses: recentPresses,
            timeWindowSeconds: 0.3  // 300ms window
        )

        // When: Getting keys in time window
        let keysInWindow = state.keysInTimeWindow

        // Then: All three keys should be returned (all within 300ms)
        XCTAssertEqual(keysInWindow.count, 3)
        XCTAssertTrue(keysInWindow.contains(0x00))
        XCTAssertTrue(keysInWindow.contains(0x01))
        XCTAssertTrue(keysInWindow.contains(0x02))
    }

    func testKeysInTimeWindowExcludesOldKeys() {
        // Given: A KeyboardState with some old key presses outside the window
        let now = Date()
        let recentPresses = [
            TimestampedKeyEvent(keyCode: 0x00, timestamp: now.addingTimeInterval(-0.1)),  // A - 100ms ago (in window)
            TimestampedKeyEvent(keyCode: 0x01, timestamp: now.addingTimeInterval(-0.5)),  // S - 500ms ago (outside)
            TimestampedKeyEvent(keyCode: 0x02, timestamp: now.addingTimeInterval(-1.0))   // D - 1000ms ago (outside)
        ]
        let state = KeyboardState(
            recentKeyPresses: recentPresses,
            timeWindowSeconds: 0.3  // 300ms window
        )

        // When: Getting keys in time window
        let keysInWindow = state.keysInTimeWindow

        // Then: Only the recent key should be returned
        XCTAssertEqual(keysInWindow.count, 1)
        XCTAssertTrue(keysInWindow.contains(0x00))
        XCTAssertFalse(keysInWindow.contains(0x01))
        XCTAssertFalse(keysInWindow.contains(0x02))
    }

    func testKeysForDetectionReturnsUnionOfPressedAndWindowed() {
        // Given: A KeyboardState with pressed keys and different windowed keys
        let now = Date()
        let recentPresses = [
            TimestampedKeyEvent(keyCode: 0x02, timestamp: now.addingTimeInterval(-0.1)),  // D - in window
            TimestampedKeyEvent(keyCode: 0x03, timestamp: now.addingTimeInterval(-0.2))   // F - in window
        ]
        let state = KeyboardState(
            pressedKeys: [0x00, 0x01],  // A, S currently pressed
            recentKeyPresses: recentPresses,
            timeWindowSeconds: 0.3
        )

        // When: Getting keys for detection
        let keysForDetection = state.keysForDetection

        // Then: Union of pressed (A, S) and windowed (D, F) should be returned
        XCTAssertEqual(keysForDetection.count, 4)
        XCTAssertTrue(keysForDetection.contains(0x00))  // A
        XCTAssertTrue(keysForDetection.contains(0x01))  // S
        XCTAssertTrue(keysForDetection.contains(0x02))  // D
        XCTAssertTrue(keysForDetection.contains(0x03))  // F
    }

    func testKeysForDetectionExcludesModifiers() {
        // Given: A KeyboardState with modifier keys in both pressed and windowed
        let now = Date()
        let recentPresses = [
            TimestampedKeyEvent(keyCode: 0x00, timestamp: now.addingTimeInterval(-0.1)),  // A
            TimestampedKeyEvent(keyCode: 0x37, timestamp: now.addingTimeInterval(-0.15))  // Command (modifier)
        ]
        let state = KeyboardState(
            pressedKeys: [0x01, 0x38],  // S + Shift (modifier)
            recentKeyPresses: recentPresses,
            timeWindowSeconds: 0.3
        )

        // When: Getting keys for detection
        let keysForDetection = state.keysForDetection

        // Then: Only non-modifier keys should be returned
        XCTAssertEqual(keysForDetection.count, 2)
        XCTAssertTrue(keysForDetection.contains(0x00))   // A
        XCTAssertTrue(keysForDetection.contains(0x01))   // S
        XCTAssertFalse(keysForDetection.contains(0x37))  // Command excluded
        XCTAssertFalse(keysForDetection.contains(0x38))  // Shift excluded
    }

    func testKeyPressedPrunesOldEntries() {
        // Given: A KeyboardState with old key presses
        let now = Date()
        let oldPresses = [
            TimestampedKeyEvent(keyCode: 0x00, timestamp: now.addingTimeInterval(-1.0)),  // A - 1s ago
            TimestampedKeyEvent(keyCode: 0x01, timestamp: now.addingTimeInterval(-0.8))   // S - 800ms ago
        ]
        var state = KeyboardState(
            recentKeyPresses: oldPresses,
            timeWindowSeconds: 0.3  // 300ms window
        )

        // When: Pressing a new key
        let newPressTime = now.addingTimeInterval(0.1)
        state.keyPressed(0x02, at: newPressTime)  // D

        // Then: Old entries should be pruned, only new key should remain
        XCTAssertEqual(state.recentKeyPresses.count, 1)
        XCTAssertEqual(state.recentKeyPresses.first?.keyCode, 0x02)
    }

    func testKeyPressedAddsTimestampedEvent() {
        // Given: An empty KeyboardState
        var state = KeyboardState(timeWindowSeconds: 0.3)
        let pressTime = Date()

        // When: Pressing a non-modifier key
        state.keyPressed(0x00, at: pressTime)  // A

        // Then: A TimestampedKeyEvent should be added
        XCTAssertEqual(state.recentKeyPresses.count, 1)
        XCTAssertEqual(state.recentKeyPresses.first?.keyCode, 0x00)
        XCTAssertEqual(state.recentKeyPresses.first?.timestamp, pressTime)
    }

    func testKeyPressedDoesNotAddModifierToRecentPresses() {
        // Given: An empty KeyboardState
        var state = KeyboardState(timeWindowSeconds: 0.3)

        // When: Pressing a modifier key
        state.keyPressed(0x37, at: Date())  // Command

        // Then: No TimestampedKeyEvent should be added to recentKeyPresses
        XCTAssertTrue(state.recentKeyPresses.isEmpty)
        // But the key should still be in pressedKeys
        XCTAssertTrue(state.pressedKeys.contains(0x37))
    }

    func testClearAllClearsRecentKeyPresses() {
        // Given: A KeyboardState with recent key presses
        let recentPresses = [
            TimestampedKeyEvent(keyCode: 0x00, timestamp: Date()),
            TimestampedKeyEvent(keyCode: 0x01, timestamp: Date())
        ]
        var state = KeyboardState(
            pressedKeys: [0x00],
            recentKeyPresses: recentPresses,
            timeWindowSeconds: 0.3
        )

        // When: Clearing all state
        state.clearAll()

        // Then: recentKeyPresses should be empty
        XCTAssertTrue(state.recentKeyPresses.isEmpty)
    }

    func testTimeWindowInitialization() {
        // Given/When: Creating a KeyboardState with custom time window
        let state = KeyboardState(timeWindowSeconds: 0.5)

        // Then: Time window should be set correctly
        XCTAssertEqual(state.timeWindowSeconds, 0.5)
    }

    func testDefaultTimeWindow() {
        // Given/When: Creating a KeyboardState with default time window
        let state = KeyboardState()

        // Then: Default time window should be 0.3 (300ms)
        XCTAssertEqual(state.timeWindowSeconds, 0.3)
    }
}
