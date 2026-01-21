//
//  KeyboardMonitoring.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation
import CoreGraphics

/// Protocol for system-level keyboard event monitoring
protocol KeyboardMonitoring: AnyObject {
    /// Delegate to receive keyboard events
    var delegate: KeyboardMonitorDelegate? { get set }

    /// Whether the monitor is currently active
    var isMonitoring: Bool { get }

    /// Start monitoring keyboard events
    /// - Throws: PermissionError if accessibility permission not granted
    func startMonitoring() throws

    /// Stop monitoring keyboard events
    func stopMonitoring()

    /// Check if app has required Input Monitoring permission
    func hasPermission() -> Bool

    /// Request Input Monitoring permission (shows system dialog)
    func requestPermission()
}
