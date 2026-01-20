//
//  LockState.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Current state of the lock system
enum LockStatus: Equatable {
    /// Normal operation, watching for patterns
    case monitoring

    /// Pattern detected, waiting for persistence
    case debouncing

    /// Keyboard locked, blocking input
    case locked

    /// After manual unlock, ignoring detection
    case cooldown
}

/// Represents the keyboard lock state machine
struct LockState {
    // MARK: - Properties

    /// Current state of the lock system
    var status: LockStatus

    /// Timestamp when lock was activated (nil if not locked)
    var lockedAt: Date?

    /// The detection event that triggered the lock
    var lockReason: DetectionEvent?

    /// When cooldown expires after manual unlock
    var cooldownUntil: Date?

    /// Timestamp of last periodic re-check
    var lastRecheckAt: Date?

    // MARK: - Initialization

    init(
        status: LockStatus = .monitoring,
        lockedAt: Date? = nil,
        lockReason: DetectionEvent? = nil,
        cooldownUntil: Date? = nil,
        lastRecheckAt: Date? = nil
    ) {
        self.status = status
        self.lockedAt = lockedAt
        self.lockReason = lockReason
        self.cooldownUntil = cooldownUntil
        self.lastRecheckAt = lastRecheckAt
    }

    // MARK: - Computed Properties

    /// Whether the cooldown period has expired
    var isCooldownExpired: Bool {
        guard let until = cooldownUntil else { return true }
        return Date() >= until
    }

    // MARK: - State Transitions

    /// Begin debounce period for a detected pattern
    mutating func beginDebounce(for detection: DetectionEvent) {
        guard status == .monitoring else { return }
        status = .debouncing
    }

    /// Cancel debounce and return to monitoring
    mutating func cancelDebounce() {
        guard status == .debouncing else { return }
        status = .monitoring
    }

    /// Lock the keyboard due to a detection event
    mutating func lock(reason: DetectionEvent) {
        status = .locked
        lockedAt = Date()
        var reasonWithLock = reason
        reasonWithLock.triggeredLock = true
        lockReason = reasonWithLock
    }

    /// Manual unlock via popup, menu, or emergency shortcut (enters cooldown)
    mutating func manualUnlock(cooldownDuration: TimeInterval) {
        status = .cooldown
        lockedAt = nil
        lockReason = nil
        lastRecheckAt = nil
        cooldownUntil = Date().addingTimeInterval(cooldownDuration)
    }

    /// End cooldown period and return to monitoring
    mutating func endCooldown() {
        guard status == .cooldown else { return }
        status = .monitoring
        cooldownUntil = nil
    }

    /// Record a re-check timestamp
    mutating func recordRecheck() {
        lastRecheckAt = Date()
    }
}
