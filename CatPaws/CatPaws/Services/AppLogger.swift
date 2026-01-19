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
    ///   - from: The previous state
    ///   - to: The new state
    static func logStateTransition(from: String, to: String) {
        guard isDebugEnabled else { return }
        lock.info("State transition: \(from) -> \(to)")
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
}
