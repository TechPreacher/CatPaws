//
//  DetectionEvent.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Type of cat detection pattern
enum DetectionType: Equatable {
    /// 3-9 adjacent non-modifier keys (single paw)
    case paw

    /// Multiple disconnected clusters of adjacent keys
    case multiPaw

    /// 10+ keys pressed (cat sitting or lying on keyboard)
    case sitting
}

/// Represents a detected cat pattern event
struct DetectionEvent: Identifiable, Equatable {
    /// Unique identifier for the detection event
    let id: UUID

    /// Type of detection pattern
    let type: DetectionType

    /// Number of non-modifier keys involved
    let keyCount: Int

    /// When the pattern was first detected
    let timestamp: Date

    /// Whether this event triggered a keyboard lock
    var triggeredLock: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: DetectionType,
        keyCount: Int,
        timestamp: Date = Date(),
        triggeredLock: Bool = false
    ) {
        self.id = id
        self.type = type
        self.keyCount = keyCount
        self.timestamp = timestamp
        self.triggeredLock = triggeredLock
    }
}
