//
//  KeyboardLockServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

final class KeyboardLockServiceTests: XCTestCase {
    var sut: KeyboardLockService!

    override func setUp() {
        super.setUp()
        sut = KeyboardLockService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T033: shouldPassThrough Returns False When Locked

    func testIsLockedInitiallyFalse() {
        XCTAssertFalse(sut.isLocked)
    }

    func testLockSetsIsLockedTrue() {
        sut.lock()
        XCTAssertTrue(sut.isLocked)
    }

    func testUnlockSetsIsLockedFalse() {
        sut.lock()
        XCTAssertTrue(sut.isLocked)

        sut.unlock()
        XCTAssertFalse(sut.isLocked)
    }

    func testShouldBlockEventWhenLocked() {
        sut.lock()
        XCTAssertTrue(sut.shouldBlockEvent())
    }

    func testShouldNotBlockEventWhenUnlocked() {
        XCTAssertFalse(sut.shouldBlockEvent())
    }

    // MARK: - T034: Debounce Tests (simulated - actual timing tested in LockStateManager)

    func testMultipleLockCallsAreSafe() {
        sut.lock()
        sut.lock()
        sut.lock()
        XCTAssertTrue(sut.isLocked)
    }

    func testMultipleUnlockCallsAreSafe() {
        sut.lock()
        sut.unlock()
        sut.unlock()
        sut.unlock()
        XCTAssertFalse(sut.isLocked)
    }
}
