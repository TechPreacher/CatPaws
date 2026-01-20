//
//  MockKeyboardLocking.swift
//  CatPawsTests
//
//  Created on 2026-01-20.
//

import Foundation
@testable import CatPaws

/// Mock implementation of KeyboardLocking for testing
final class MockKeyboardLocking: KeyboardLocking {
    // MARK: - Properties

    private(set) var isLocked: Bool = false

    // MARK: - Call Tracking

    private(set) var lockCallCount: Int = 0
    private(set) var unlockCallCount: Int = 0

    // MARK: - KeyboardLocking Protocol

    func lock() {
        lockCallCount += 1
        isLocked = true
    }

    func unlock() {
        unlockCallCount += 1
        isLocked = false
    }

    // MARK: - Testing Support

    func reset() {
        isLocked = false
        lockCallCount = 0
        unlockCallCount = 0
    }
}
