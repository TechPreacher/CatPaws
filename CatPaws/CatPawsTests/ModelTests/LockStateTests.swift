//
//  LockStateTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

final class LockStateTests: XCTestCase {
    // MARK: - T030: Initial State Tests

    func testDefaultInitialization() {
        let state = LockState()
        XCTAssertEqual(state.status, .monitoring)
        XCTAssertNil(state.lockedAt)
        XCTAssertNil(state.lockReason)
        XCTAssertNil(state.cooldownUntil)
    }

    // MARK: - T031: State Transitions

    func testTransitionMonitoringToDebouncing() {
        var state = LockState()
        XCTAssertEqual(state.status, .monitoring)

        let detection = DetectionEvent(type: .paw, keyCount: 3)
        state.beginDebounce(for: detection)

        XCTAssertEqual(state.status, .debouncing)
    }

    func testTransitionDebouncingToMonitoring() {
        var state = LockState(status: .debouncing)
        state.cancelDebounce()

        XCTAssertEqual(state.status, .monitoring)
    }

    func testTransitionDebouncingToLocked() {
        var state = LockState(status: .debouncing)
        let detection = DetectionEvent(type: .paw, keyCount: 3)

        state.lock(reason: detection)

        XCTAssertEqual(state.status, .locked)
        XCTAssertNotNil(state.lockedAt)
        XCTAssertEqual(state.lockReason?.type, .paw)
    }

    func testTransitionLockedToCooldown() {
        let detection = DetectionEvent(type: .paw, keyCount: 3)
        var state = LockState(status: .locked, lockedAt: Date(), lockReason: detection)
        let cooldownDuration: TimeInterval = 7.0

        state.manualUnlock(cooldownDuration: cooldownDuration)

        XCTAssertEqual(state.status, .cooldown)
        XCTAssertNotNil(state.cooldownUntil)
        XCTAssertNil(state.lockedAt)
        XCTAssertNil(state.lockReason)
    }

    func testTransitionCooldownToMonitoring() {
        let cooldownUntil = Date().addingTimeInterval(-1)  // Already expired
        var state = LockState(status: .cooldown, cooldownUntil: cooldownUntil)

        state.endCooldown()

        XCTAssertEqual(state.status, .monitoring)
        XCTAssertNil(state.cooldownUntil)
    }

    // MARK: - Validation Rules

    func testLockedAtClearedOnManualUnlock() {
        let detection = DetectionEvent(type: .paw, keyCount: 3)
        var state = LockState(status: .locked, lockedAt: Date(), lockReason: detection)

        XCTAssertNotNil(state.lockedAt)

        state.manualUnlock(cooldownDuration: 5.0)

        XCTAssertNil(state.lockedAt)
    }

    func testCooldownUntilOnlyWhenCooldown() {
        let detection = DetectionEvent(type: .paw, keyCount: 3)
        var state = LockState(status: .locked, lockedAt: Date(), lockReason: detection)
        state.manualUnlock(cooldownDuration: 5.0)

        XCTAssertNotNil(state.cooldownUntil)
        XCTAssertEqual(state.status, .cooldown)

        state.endCooldown()

        XCTAssertNil(state.cooldownUntil)
        XCTAssertEqual(state.status, .monitoring)
    }

    // MARK: - Cooldown Expired Check

    func testIsCooldownExpired() {
        // Not expired yet
        var state = LockState(
            status: .cooldown,
            cooldownUntil: Date().addingTimeInterval(5.0)
        )
        XCTAssertFalse(state.isCooldownExpired)

        // Already expired
        state = LockState(
            status: .cooldown,
            cooldownUntil: Date().addingTimeInterval(-1.0)
        )
        XCTAssertTrue(state.isCooldownExpired)
    }

    // MARK: - Lock Persistence

    func testLockStateRequiresManualUnlock() {
        let detection = DetectionEvent(type: .paw, keyCount: 3)
        var state = LockState(status: .locked, lockedAt: Date(), lockReason: detection)

        // Lock persists - only manual unlock changes state
        XCTAssertEqual(state.status, .locked)

        state.manualUnlock(cooldownDuration: 5.0)

        XCTAssertEqual(state.status, .cooldown)
    }
}
