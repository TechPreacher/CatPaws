//
//  AppLogger.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation
import os

/// Centralized logging utility using os.Logger
/// Filter in Console.app with: subsystem:com.corti.CatPaws
/// Logging is conditional based on Configuration.debugLoggingEnabled
struct AppLogger {
    /// The app's logging subsystem identifier
    static let subsystem = "com.corti.CatPaws"

    // MARK: - Category-Specific Loggers

    /// Logger for cat detection events
    static let detection = Logger(subsystem: subsystem, category: "detection")

    /// Logger for keyboard lock/unlock events
    static let lock = Logger(subsystem: subsystem, category: "lock")

    /// Logger for permission-related events
    static let permission = Logger(subsystem: subsystem, category: "permission")

    /// Logger for general app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Logger for statistics events
    static let statistics = Logger(subsystem: subsystem, category: "statistics")

    /// Logger for purr detection events
    static let purr = Logger(subsystem: subsystem, category: "purr")

    /// Logger for audio monitoring events
    static let audio = Logger(subsystem: subsystem, category: "audio")

    // MARK: - Debug Logging Check

    /// Check if debug logging is enabled
    /// Uses UserDefaults directly to avoid circular dependencies
    private static var isDebugEnabled: Bool {
        UserDefaults.standard.bool(forKey: "catpaws.debugLogging")
    }

    // MARK: - Convenience Methods

    /// Logs a cat pattern detection event (key count only, NO key content for privacy)
    /// - Parameter keyCount: Number of keys detected
    static func logDetection(keyCount: Int) {
        guard isDebugEnabled else { return }
        detection.info("Cat pattern detected with \(keyCount) keys")
    }

    /// Logs a detection type event
    /// - Parameter type: The type of detection (paw, multiPaw, sitting)
    static func logDetectionType(_ type: String) {
        guard isDebugEnabled else { return }
        detection.info("Detection type: \(type)")
    }

    /// Logs a keyboard lock event
    static func logLock() {
        guard isDebugEnabled else { return }
        lock.info("Keyboard locked due to cat detection")
    }

    /// Logs a keyboard unlock event
    /// - Parameter reason: The reason for unlocking
    static func logUnlock(reason: String) {
        guard isDebugEnabled else { return }
        lock.info("Keyboard unlocked: \(reason)")
    }

    /// Logs a state transition
    /// - Parameters:
    ///   - fromState: The previous state
    ///   - toState: The new state
    static func logStateTransition(fromState: String, toState: String) {
        guard isDebugEnabled else { return }
        lock.info("State transition: \(fromState) -> \(toState)")
    }

    /// Logs a debounce event
    static func logDebounce() {
        guard isDebugEnabled else { return }
        lock.info("Debounce triggered - waiting for key release")
    }

    /// Logs a cooldown event
    /// - Parameter duration: The cooldown duration in seconds
    static func logCooldown(duration: Double) {
        guard isDebugEnabled else { return }
        lock.info("Cooldown started: \(duration, format: .fixed(precision: 1))s")
    }

    /// Logs a permission status change
    /// - Parameter granted: Whether permission is now granted
    static func logPermissionChange(granted: Bool) {
        guard isDebugEnabled else { return }
        permission.info("Input monitoring permission: \(granted ? "granted" : "denied")")
    }

    /// Logs permission check events
    /// - Parameter status: Description of the permission status
    static func logPermissionCheck(_ status: String) {
        guard isDebugEnabled else { return }
        permission.info("Permission check: \(status)")
    }

    /// Logs app lifecycle events
    /// - Parameter event: Description of the lifecycle event
    static func logAppEvent(_ event: String) {
        guard isDebugEnabled else { return }
        app.info("\(event)")
    }

    /// Logs statistics updates
    /// - Parameter message: Statistics update description
    static func logStatistics(_ message: String) {
        guard isDebugEnabled else { return }
        statistics.info("\(message)")
    }

    // MARK: - Purr Detection Logging

    /// Logs audio monitoring start
    static func logAudioMonitoringStarted() {
        guard isDebugEnabled else { return }
        audio.info("Audio monitoring started")
    }

    /// Logs audio monitoring stop
    static func logAudioMonitoringStopped() {
        guard isDebugEnabled else { return }
        audio.info("Audio monitoring stopped")
    }

    /// Logs audio level threshold exceeded
    /// - Parameter level: The RMS level that was detected
    static func logAudioThresholdExceeded(level: Float) {
        guard isDebugEnabled else { return }
        audio.debug("Audio threshold exceeded: RMS=\(level, format: .fixed(precision: 4))")
    }

    /// Logs purr detection initialization
    static func logPurrDetectionInitialized() {
        guard isDebugEnabled else { return }
        purr.info("Purr detection service initialized")
    }

    /// Logs purr detection result
    /// - Parameters:
    ///   - detected: Whether a purr was detected
    ///   - confidence: The confidence score
    static func logPurrDetectionResult(detected: Bool, confidence: Float) {
        guard isDebugEnabled else { return }
        if detected {
            purr.info("Cat purr DETECTED with confidence: \(confidence, format: .fixed(precision: 2))")
        } else {
            purr.debug("No purr detected, confidence: \(confidence, format: .fixed(precision: 2))")
        }
    }

    /// Logs purr sensitivity change
    /// - Parameter sensitivity: The new sensitivity value
    static func logPurrSensitivityChanged(sensitivity: Float) {
        guard isDebugEnabled else { return }
        purr.info("Purr detection sensitivity changed to: \(sensitivity, format: .fixed(precision: 2))")
    }

    /// Logs microphone permission status
    /// - Parameter granted: Whether microphone permission is granted
    static func logMicrophonePermission(granted: Bool) {
        guard isDebugEnabled else { return }
        permission.info("Microphone permission: \(granted ? "granted" : "denied")")
    }

    /// Logs purr-triggered keyboard lock
    static func logPurrTriggeredLock() {
        guard isDebugEnabled else { return }
        purr.info("Keyboard locked due to cat purr detection")
    }
}
