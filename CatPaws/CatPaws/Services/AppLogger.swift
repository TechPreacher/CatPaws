//
//  AppLogger.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation
import os

/// Centralized logging utility using os.Logger
/// Filter in Console.app with: subsystem:com.catpaws.app
struct AppLogger {
    /// The app's logging subsystem identifier
    static let subsystem = "com.catpaws.app"

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

    // MARK: - Convenience Methods

    /// Logs a cat pattern detection event
    /// - Parameter keyCount: Number of keys detected (no key content for privacy)
    static func logDetection(keyCount: Int) {
        detection.info("Cat pattern detected with \(keyCount) keys")
    }

    /// Logs a keyboard lock event
    static func logLock() {
        lock.info("Keyboard locked due to cat detection")
    }

    /// Logs a keyboard unlock event
    /// - Parameter reason: The reason for unlocking
    static func logUnlock(reason: String) {
        lock.info("Keyboard unlocked: \(reason)")
    }

    /// Logs a permission status change
    /// - Parameter granted: Whether permission is now granted
    static func logPermissionChange(granted: Bool) {
        permission.info("Input monitoring permission: \(granted ? "granted" : "denied")")
    }

    /// Logs app lifecycle events
    /// - Parameter event: Description of the lifecycle event
    static func logAppEvent(_ event: String) {
        app.info("\(event)")
    }

    /// Logs statistics updates
    /// - Parameter message: Statistics update description
    static func logStatistics(_ message: String) {
        statistics.info("\(message)")
    }
}
