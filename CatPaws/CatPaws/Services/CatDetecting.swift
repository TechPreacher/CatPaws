//
//  CatDetecting.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Protocol for cat paw detection services
protocol CatDetecting {
    /// Analyze pressed keys for cat paw patterns
    /// - Parameter pressedKeys: Set of currently pressed key codes
    /// - Returns: DetectionEvent if a pattern is detected, nil otherwise
    func analyzePattern(pressedKeys: Set<UInt16>) -> DetectionEvent?

    /// Check if a set of keys forms a connected cluster
    /// - Parameter keys: Set of key codes to check
    /// - Returns: true if all keys are connected via adjacency
    func formsConnectedCluster(_ keys: Set<UInt16>) -> Bool
}
