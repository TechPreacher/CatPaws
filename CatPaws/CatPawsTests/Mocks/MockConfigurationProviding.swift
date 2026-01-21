//
//  MockConfigurationProviding.swift
//  CatPawsTests
//
//  Created on 2026-01-20.
//

import Foundation
@testable import CatPaws

/// Mock implementation of ConfigurationProviding for testing
final class MockConfigurationProviding: ConfigurationProviding {
    // MARK: - ConfigurationProviding Protocol

    var isEnabled: Bool = true
    var debounceMs: Int = 300
    var cooldownSec: Double = 5.0
    var minimumKeyCount: Int = 3
    var playSoundOnLock: Bool = true
    var playSoundOnUnlock: Bool = true
    var detectionTimeWindowMs: Int = 300

    // MARK: - Call Tracking

    private(set) var resetToDefaultsCallCount: Int = 0

    // MARK: - ConfigurationProviding Protocol

    func resetToDefaults() {
        resetToDefaultsCallCount += 1
        isEnabled = true
        debounceMs = 300
        cooldownSec = 5.0
        minimumKeyCount = 3
        playSoundOnLock = true
        playSoundOnUnlock = true
        detectionTimeWindowMs = 300
    }

    // MARK: - Testing Support

    func reset() {
        resetToDefaultsCallCount = 0
        resetToDefaults()
    }
}
