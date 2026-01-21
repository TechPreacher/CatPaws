//
//  MockCatDetecting.swift
//  CatPawsTests
//
//  Created on 2026-01-20.
//

import Foundation
@testable import CatPaws

/// Mock implementation of CatDetecting for testing
final class MockCatDetecting: CatDetecting {
    // MARK: - Configurable Responses

    /// The event to return from analyzePattern, or nil for no detection
    var stubbedDetectionEvent: DetectionEvent?

    /// Whether formsConnectedCluster should return true
    var stubbedFormsConnectedCluster: Bool = false

    // MARK: - Call Tracking

    private(set) var analyzePatternCallCount: Int = 0
    private(set) var lastAnalyzedKeys: Set<UInt16> = []

    private(set) var formsConnectedClusterCallCount: Int = 0
    private(set) var lastClusterKeys: Set<UInt16> = []

    // MARK: - CatDetecting Protocol

    func analyzePattern(pressedKeys: Set<UInt16>) -> DetectionEvent? {
        analyzePatternCallCount += 1
        lastAnalyzedKeys = pressedKeys
        return stubbedDetectionEvent
    }

    func formsConnectedCluster(_ keys: Set<UInt16>) -> Bool {
        formsConnectedClusterCallCount += 1
        lastClusterKeys = keys
        return stubbedFormsConnectedCluster
    }

    // MARK: - Testing Support

    func reset() {
        stubbedDetectionEvent = nil
        stubbedFormsConnectedCluster = false
        analyzePatternCallCount = 0
        lastAnalyzedKeys = []
        formsConnectedClusterCallCount = 0
        lastClusterKeys = []
    }
}
