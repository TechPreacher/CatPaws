//
//  DetectionLockUnlockIntegrationTests.swift
//  CatPawsTests
//
//  Created on 2026-01-16.
//

import XCTest
@testable import CatPaws

/// Integration tests for the full detection→lock→unlock flow
/// These tests verify that all components work together correctly
final class DetectionLockUnlockIntegrationTests: XCTestCase {

    var catDetectionService: CatDetectionService!
    var lockStateManager: LockStateManager!
    var lockService: KeyboardLockService!
    var mockNotificationPresenter: MockNotificationPresenter!
    var configuration: Configuration!
    var keyboardState: KeyboardState!

    override func setUp() {
        super.setUp()

        // Initialize all services
        catDetectionService = CatDetectionService()
        lockService = KeyboardLockService()
        lockStateManager = LockStateManager()
        mockNotificationPresenter = MockNotificationPresenter()
        configuration = Configuration()
        keyboardState = KeyboardState()

        // Wire up services
        lockStateManager.lockService = lockService
        lockStateManager.notificationPresenter = mockNotificationPresenter
        lockStateManager.configuration = configuration

        // Configure detection service
        catDetectionService.minimumKeyCount = configuration.minimumKeyCount
    }

    override func tearDown() {
        catDetectionService = nil
        lockStateManager = nil
        lockService = nil
        mockNotificationPresenter = nil
        configuration = nil
        keyboardState = nil
        super.tearDown()
    }

    // MARK: - Full Detection→Lock→Auto-Unlock Flow

    /// Test: Simulates a cat paw pressing keys, then leaving, resulting in auto-unlock
    func testFullDetectionLockAutoUnlockFlow() async throws {
        // 1. Verify initial state
        XCTAssertEqual(lockStateManager.state.status, .monitoring)
        XCTAssertFalse(lockService.isLocked)
        XCTAssertEqual(mockNotificationPresenter.showCallCount, 0)

        // 2. Simulate cat paw pressing A, S, D, F keys (adjacent keys on QWERTY)
        let catPawKeys: Set<UInt16> = [0x00, 0x01, 0x02, 0x03]  // A=0x00, S=0x01, D=0x02, F=0x03
        for keyCode in catPawKeys {
            keyboardState.keyPressed(keyCode)
        }

        // 3. Analyze pattern - should detect cat paw
        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)
        XCTAssertNotNil(detection, "Should detect cat paw pattern")
        XCTAssertEqual(detection?.type, .paw)

        // 4. Handle detection
        lockStateManager.handleDetection(detection!)

        // 5. Verify debouncing state
        XCTAssertEqual(lockStateManager.state.status, .debouncing)
        XCTAssertFalse(lockService.isLocked, "Should not be locked during debounce")

        // 6. Wait for debounce period to complete (300ms default + buffer)
        try await Task.sleep(nanoseconds: 400_000_000)

        // 7. Verify locked state
        XCTAssertEqual(lockStateManager.state.status, .locked)
        XCTAssertTrue(lockService.isLocked, "Keyboard should be locked")
        XCTAssertEqual(mockNotificationPresenter.showCallCount, 1, "Notification should be shown")
        XCTAssertEqual(mockNotificationPresenter.lastShownDetectionType, .paw)

        // 8. Simulate cat leaving - release all keys
        for keyCode in catPawKeys {
            keyboardState.keyReleased(keyCode)
        }

        // 9. Perform recheck with no keys pressed (simulates auto-unlock timer)
        lockStateManager.performRecheck(pressedKeyCount: keyboardState.nonModifierKeys.count)

        // 10. Verify unlocked state
        XCTAssertEqual(lockStateManager.state.status, .monitoring)
        XCTAssertFalse(lockService.isLocked, "Keyboard should be unlocked")
        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 1, "Notification should be hidden")
    }

    // MARK: - Full Detection→Lock→Manual-Unlock→Cooldown Flow

    /// Test: Simulates a cat paw pressing keys, user manually unlocking, then cooldown
    func testFullDetectionLockManualUnlockCooldownFlow() async throws {
        // 1. Simulate cat paw
        let catPawKeys: Set<UInt16> = [0x00, 0x01, 0x02]  // A, S, D
        for keyCode in catPawKeys {
            keyboardState.keyPressed(keyCode)
        }

        // 2. Detect and lock
        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)
        XCTAssertNotNil(detection)
        lockStateManager.handleDetection(detection!)

        // 3. Wait for debounce
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(lockStateManager.state.status, .locked)

        // 4. Manual unlock (user presses dismiss button)
        mockNotificationPresenter.simulateDismiss()

        // 5. Verify cooldown state
        XCTAssertEqual(lockStateManager.state.status, .cooldown)
        XCTAssertFalse(lockService.isLocked)
        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 1)

        // 6. Try to trigger detection during cooldown - should be ignored
        let newDetection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)
        if let newDetection = newDetection {
            lockStateManager.handleDetection(newDetection)
        }

        // 7. Should still be in cooldown
        XCTAssertEqual(lockStateManager.state.status, .cooldown, "Detection during cooldown should be ignored")
    }

    // MARK: - Multi-Paw Detection Flow

    /// Test: Simulates multiple cat paws pressing separate key clusters
    func testMultiPawDetectionFlow() async throws {
        // Simulate two separate clusters (e.g., front and back paws)
        // Cluster 1: Q, W, E (top row)
        // Cluster 2: Z, X, C (bottom row) - not adjacent to cluster 1

        // Note: For this test, we need clusters that are NOT connected
        // Q=0x0C, W=0x0D, E=0x0E (top row)
        // Z=0x06, X=0x07, C=0x08 (bottom row)

        let cluster1: Set<UInt16> = [0x0C, 0x0D, 0x0E]  // Q, W, E
        let cluster2: Set<UInt16> = [0x06, 0x07, 0x08]  // Z, X, C
        let allKeys = cluster1.union(cluster2)

        for keyCode in allKeys {
            keyboardState.keyPressed(keyCode)
        }

        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)

        // Should detect multi-paw pattern
        XCTAssertNotNil(detection, "Should detect multi-paw pattern")
        XCTAssertEqual(detection?.type, .multiPaw)

        // Lock and verify
        lockStateManager.handleDetection(detection!)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(lockStateManager.state.status, .locked)
        XCTAssertEqual(mockNotificationPresenter.lastShownDetectionType, .multiPaw)
    }

    // MARK: - Sitting Cat Detection Flow

    /// Test: Simulates a cat sitting on the keyboard (10+ keys)
    func testSittingCatDetectionFlow() async throws {
        // Simulate 12 keys pressed (cat sitting/lying on keyboard)
        // A row: A(0x00), S(0x01), D(0x02), F(0x03), G(0x05), H(0x04)
        // Q row: Q(0x0C), W(0x0D), E(0x0E), R(0x0F), T(0x11), Y(0x10)
        let sittingKeys: Set<UInt16> = [
            0x00, 0x01, 0x02, 0x03, 0x05, 0x04,  // A, S, D, F, G, H
            0x0C, 0x0D, 0x0E, 0x0F, 0x11, 0x10   // Q, W, E, R, T, Y
        ]

        for keyCode in sittingKeys {
            keyboardState.keyPressed(keyCode)
        }

        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)

        // Should detect sitting pattern
        XCTAssertNotNil(detection, "Should detect sitting pattern")
        XCTAssertEqual(detection?.type, .sitting)
        XCTAssertEqual(detection?.keyCount, 12)

        // Lock and verify
        lockStateManager.handleDetection(detection!)
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(lockStateManager.state.status, .locked)
        XCTAssertEqual(mockNotificationPresenter.lastShownDetectionType, .sitting)
    }

    // MARK: - Normal Typing Should Not Trigger

    /// Test: Simulates normal typing (sequential keys, not simultaneous)
    func testNormalTypingDoesNotTrigger() {
        // Simulate typing "asdf" sequentially
        let keys: [UInt16] = [0x00, 0x01, 0x02, 0x03]  // A, S, D, F

        for keyCode in keys {
            // Press and immediately release (normal typing)
            keyboardState.keyPressed(keyCode)
            let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)

            // Single key should never trigger
            XCTAssertNil(detection, "Single key should not trigger detection")

            keyboardState.keyReleased(keyCode)
        }

        XCTAssertEqual(lockStateManager.state.status, .monitoring)
    }

    // MARK: - Modifier Keys Should Not Trigger

    /// Test: Simulates pressing multiple modifier keys
    func testModifierKeysDoNotTrigger() {
        // Press Cmd + Shift + Option + Control
        let modifierKeys: Set<UInt16> = [0x37, 0x38, 0x3A, 0x3B]  // Cmd, Shift, Option, Control

        keyboardState.updateModifiers(modifierKeys)

        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)

        // Should not trigger (all modifier keys are filtered out)
        XCTAssertNil(detection, "Modifier-only keys should not trigger detection")
        XCTAssertEqual(lockStateManager.state.status, .monitoring)
    }

    // MARK: - Debounce Cancellation

    /// Test: Pattern detected but released before debounce completes
    func testDebounceCancellationFlow() async throws {
        // Press cat paw keys
        let catPawKeys: Set<UInt16> = [0x00, 0x01, 0x02, 0x03]
        for keyCode in catPawKeys {
            keyboardState.keyPressed(keyCode)
        }

        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)
        XCTAssertNotNil(detection)
        lockStateManager.handleDetection(detection!)

        // Verify debouncing
        XCTAssertEqual(lockStateManager.state.status, .debouncing)

        // Release keys before debounce completes (within 300ms)
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

        for keyCode in catPawKeys {
            keyboardState.keyReleased(keyCode)
        }
        lockStateManager.handleKeysReleased()

        // Should return to monitoring
        XCTAssertEqual(lockStateManager.state.status, .monitoring)
        XCTAssertFalse(lockService.isLocked)

        // Wait past debounce period to ensure lock doesn't happen
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(lockStateManager.state.status, .monitoring, "Should remain in monitoring after debounce cancelled")
        XCTAssertEqual(mockNotificationPresenter.showCallCount, 0, "Notification should not be shown")
    }

    // MARK: - Keyboard Remains Locked If Keys Still Pressed

    /// Test: Auto-unlock recheck while keys still pressed should keep keyboard locked
    func testRecheckWithKeysPressedKeepsLocked() async throws {
        // Press cat paw keys
        let catPawKeys: Set<UInt16> = [0x00, 0x01, 0x02, 0x03]
        for keyCode in catPawKeys {
            keyboardState.keyPressed(keyCode)
        }

        let detection = catDetectionService.analyzePattern(pressedKeys: keyboardState.nonModifierKeys)
        lockStateManager.handleDetection(detection!)

        // Wait for lock
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(lockStateManager.state.status, .locked)

        // Perform recheck while keys still pressed
        lockStateManager.performRecheck(pressedKeyCount: keyboardState.nonModifierKeys.count)

        // Should remain locked
        XCTAssertEqual(lockStateManager.state.status, .locked)
        XCTAssertTrue(lockService.isLocked)
        XCTAssertEqual(mockNotificationPresenter.hideCallCount, 0, "Notification should remain visible")
    }
}
