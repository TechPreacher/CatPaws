//
//  PurrDetectionResult.swift
//  CatPaws
//
//  Created on 2026-01-21.
//

import Foundation

/// Result of a purr detection analysis from the audio monitoring service
struct PurrDetectionResult {
    /// Confidence score (0.0 to 1.0) indicating likelihood of cat purring
    let confidence: Float

    /// Whether purr was detected above the configured sensitivity threshold
    let detected: Bool

    /// Timestamp when the detection analysis occurred
    let timestamp: Date

    /// Duration of the detected purring sound in seconds
    let duration: TimeInterval

    /// No detection result (convenience static instance)
    static let none = PurrDetectionResult(
        confidence: 0,
        detected: false,
        timestamp: Date(),
        duration: 0
    )
}

// MARK: - Equatable

extension PurrDetectionResult: Equatable {
    static func == (lhs: PurrDetectionResult, rhs: PurrDetectionResult) -> Bool {
        lhs.confidence == rhs.confidence &&
        lhs.detected == rhs.detected &&
        lhs.duration == rhs.duration
    }
}
