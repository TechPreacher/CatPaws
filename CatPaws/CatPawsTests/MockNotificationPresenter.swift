//
//  MockNotificationPresenter.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import Foundation
@testable import CatPaws

/// Mock implementation of NotificationPresenting for testing
final class MockNotificationPresenter: NotificationPresenting {
    // MARK: - Call Tracking

    var showCallCount = 0
    var hideCallCount = 0
    var lastShownDetectionType: DetectionType?
    var lastDismissCallback: (() -> Void)?

    // MARK: - NotificationPresenting

    func show(detectionType: DetectionType, onDismiss: @escaping () -> Void) {
        showCallCount += 1
        lastShownDetectionType = detectionType
        lastDismissCallback = onDismiss
    }

    func hide() {
        hideCallCount += 1
    }

    // MARK: - Test Helpers

    func reset() {
        showCallCount = 0
        hideCallCount = 0
        lastShownDetectionType = nil
        lastDismissCallback = nil
    }

    func simulateDismiss() {
        lastDismissCallback?()
    }
}
