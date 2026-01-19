//
//  LockStateManagerTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

final class LockStateManagerTests: XCTestCase {
    var sut: LockStateManager!
    var mockLockService: KeyboardLockService!
    var mockNotificationPresenter: MockNotificationPresenter!

    override func setUp() {
        super.setUp()
        sut = LockStateManager()
        mockLockService = KeyboardLockService()
        mockNotificationPresenter = MockNotificationPresenter()
        sut.lockService = mockLockService
        sut.notificationPresenter = mockNotificationPresenter
    }

    override func tearDown() {
        sut = nil
        mockLockService = nil
        mockNotificationPresenter = nil
        super.tearDown()
    }

    // MARK: - T044: Show is Called When Entering Locked State

    func testShowCalledWhenLocked() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Trigger detection
        sut.handleDetection(detection)

        // Wait for debounce (300ms default + some buffer)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(mockNotificationPresenter.showCallCount, 1)
        XCTAssertEqual(mockNotificationPresenter.lastShownDetectionType, .paw)
    }

    // MARK: - T045: Hide is Called When Exiting Locked State

    func testHideCalledOnAutoUnlock() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Trigger detection and wait for lock
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(sut.state.status, .locked)

        // Simulate auto-unlock via recheck with no keys pressed
        sut.performRecheck(pressedKeyCount: 0)

        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 1)
        XCTAssertEqual(sut.state.status, .monitoring)
    }

    func testHideCalledOnManualUnlock() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Trigger detection and wait for lock
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(sut.state.status, .locked)

        // Manual unlock
        sut.manualUnlock()

        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 1)
        XCTAssertEqual(sut.state.status, .cooldown)
    }

    // MARK: - T046: Dismiss Callback Triggers ManualUnlock

    func testDismissCallbackTriggersManualUnlock() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Trigger detection and wait for lock
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(sut.state.status, .locked)

        // Simulate user pressing dismiss button
        mockNotificationPresenter.simulateDismiss()

        XCTAssertEqual(sut.state.status, .cooldown)
        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 1)
    }

    // MARK: - State Machine Tests

    func testDebounceCanBeCancelled() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Trigger detection
        sut.handleDetection(detection)
        XCTAssertEqual(sut.state.status, .debouncing)

        // Cancel before debounce completes
        sut.handleKeysReleased()

        XCTAssertEqual(sut.state.status, .monitoring)

        // Wait to ensure lock doesn't happen
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(sut.state.status, .monitoring)
        XCTAssertEqual(mockNotificationPresenter.showCallCount, 0)
    }

    func testCooldownIgnoresDetection() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Lock and then manual unlock to enter cooldown
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)
        sut.manualUnlock()

        XCTAssertEqual(sut.state.status, .cooldown)

        // New detection during cooldown
        let newDetection = DetectionEvent(type: .paw, keyCount: 4)
        sut.handleDetection(newDetection)

        // Should still be in cooldown
        XCTAssertEqual(sut.state.status, .cooldown)
    }

    // MARK: - T054-T056: Automatic Unlock Tests

    func testPerformRecheckUnlocksWhenNoKeysPressed() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Lock the keyboard
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(sut.state.status, .locked)
        XCTAssertTrue(mockLockService.isLocked)

        // Perform recheck with no keys pressed
        sut.performRecheck(pressedKeyCount: 0)

        // Should unlock
        XCTAssertEqual(sut.state.status, .monitoring)
        XCTAssertFalse(mockLockService.isLocked)
    }

    func testKeyboardRemainsLockedIfKeysStillPressed() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Lock the keyboard
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(sut.state.status, .locked)

        // Perform recheck with keys still pressed
        sut.performRecheck(pressedKeyCount: 3)

        // Should remain locked
        XCTAssertEqual(sut.state.status, .locked)
        XCTAssertTrue(mockLockService.isLocked)
        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 0)
    }

    func testRecheckRecordsTimestamp() async throws {
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        // Lock the keyboard
        sut.handleDetection(detection)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertNil(sut.state.lastRecheckAt)

        // Perform recheck
        sut.performRecheck(pressedKeyCount: 3)

        XCTAssertNotNil(sut.state.lastRecheckAt)
    }
}
