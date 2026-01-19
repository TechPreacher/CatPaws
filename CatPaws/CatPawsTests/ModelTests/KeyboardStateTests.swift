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
}
