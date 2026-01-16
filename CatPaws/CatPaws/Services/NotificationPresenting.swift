//
//  NotificationPresenting.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Protocol for presenting lock notifications
protocol NotificationPresenting: AnyObject {
    /// Show the lock notification
    /// - Parameters:
    ///   - detectionType: The type of detection that triggered the lock
    ///   - onDismiss: Callback when user dismisses the notification
    func show(detectionType: DetectionType, onDismiss: @escaping () -> Void)

    /// Hide the lock notification
    func hide()
}
