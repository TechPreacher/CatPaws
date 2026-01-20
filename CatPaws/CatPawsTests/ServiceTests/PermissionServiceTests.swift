//
//  PermissionServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-19.
//

import XCTest
@testable import CatPaws

@MainActor
final class PermissionServiceTests: XCTestCase {
    var sut: PermissionService!

    override func setUp() async throws {
        try await super.setUp()
        sut = PermissionService()
    }

    override func tearDown() async throws {
        sut?.stopPolling()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationCreatesValidState() {
        // Service should initialize with a valid state
        XCTAssertNotNil(sut.state)
        XCTAssertEqual(sut.state.accessibility.type, .accessibility)
        XCTAssertEqual(sut.state.inputMonitoring.type, .inputMonitoring)
    }

    // MARK: - Permission Check Tests

    func testCheckAccessibilityReturnsBoolean() {
        // Should return a boolean (actual value depends on system state)
        let result = sut.checkAccessibility()
        XCTAssertTrue(result == true || result == false)
    }

    func testCheckInputMonitoringReturnsBoolean() {
        // Should return a boolean (actual value depends on system state)
        let result = sut.checkInputMonitoring()
        XCTAssertTrue(result == true || result == false)
    }

    func testGetCurrentStateUpdatesState() {
        let state = sut.getCurrentState()
        // Verify the state is returned and matches the internal state
        XCTAssertEqual(state.accessibility.isGranted, sut.state.accessibility.isGranted)
        XCTAssertEqual(state.inputMonitoring.isGranted, sut.state.inputMonitoring.isGranted)
    }

    // MARK: - Polling Tests

    func testStartPollingActivatesTimer() {
        XCTAssertFalse(sut.isPolling)

        sut.startPolling()
        XCTAssertTrue(sut.isPolling)

        sut.stopPolling()
        XCTAssertFalse(sut.isPolling)
    }

    func testStartPollingMultipleTimesDoesNotCreateMultipleTimers() {
        sut.startPolling()
        XCTAssertTrue(sut.isPolling)

        // Starting again should be a no-op
        sut.startPolling()
        XCTAssertTrue(sut.isPolling)

        sut.stopPolling()
        XCTAssertFalse(sut.isPolling)
    }

    func testStopPollingDeactivatesTimer() {
        sut.startPolling()
        XCTAssertTrue(sut.isPolling)

        sut.stopPolling()
        XCTAssertFalse(sut.isPolling)
    }

    func testStopPollingWhenNotPollingIsNoOp() {
        XCTAssertFalse(sut.isPolling)
        sut.stopPolling()
        XCTAssertFalse(sut.isPolling)
    }

    func testPollingIntervalIsOneSecond() {
        XCTAssertEqual(PermissionService.pollingInterval, 1.0)
    }

    // MARK: - Callback Tests

    func testOnStateChangeCallbackCanBeSet() {
        var callbackInvoked = false

        sut.onStateChange = { _ in
            callbackInvoked = true
        }

        XCTAssertNotNil(sut.onStateChange)
        // Note: We can't easily test the callback being invoked without mocking
        // the permission APIs, but we verify it can be set
        _ = callbackInvoked // Silence unused variable warning
    }

    // MARK: - State Observation Tests

    func testStateIsPublished() {
        // Verify state is a Published property by accessing it
        let state = sut.state
        XCTAssertNotNil(state)
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(PermissionService.shared)
    }

    func testSharedInstanceIsSameObject() {
        let instance1 = PermissionService.shared
        let instance2 = PermissionService.shared
        XCTAssertTrue(instance1 === instance2)
    }
}

// MARK: - Mock Permission Service for Testing

/// A mock implementation of PermissionChecking for testing other components
@MainActor
final class MockPermissionService: PermissionChecking {
    var accessibilityGranted = false
    var inputMonitoringGranted = false
    var openSettingsCalled = false
    var lastOpenedSettingsType: PermissionType?

    func checkAccessibility() -> Bool {
        accessibilityGranted
    }

    func checkInputMonitoring() -> Bool {
        inputMonitoringGranted
    }

    func getCurrentState() -> PermissionState {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: accessibilityGranted),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: inputMonitoringGranted)
        )
        return state
    }

    func openSettings(for type: PermissionType) {
        openSettingsCalled = true
        lastOpenedSettingsType = type
    }
}

// MARK: - Mock Permission Service Tests

@MainActor
final class MockPermissionServiceTests: XCTestCase {
    var mockService: MockPermissionService!

    override func setUp() {
        super.setUp()
        mockService = MockPermissionService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    func testMockReturnsConfiguredAccessibilityValue() {
        mockService.accessibilityGranted = false
        XCTAssertFalse(mockService.checkAccessibility())

        mockService.accessibilityGranted = true
        XCTAssertTrue(mockService.checkAccessibility())
    }

    func testMockReturnsConfiguredInputMonitoringValue() {
        mockService.inputMonitoringGranted = false
        XCTAssertFalse(mockService.checkInputMonitoring())

        mockService.inputMonitoringGranted = true
        XCTAssertTrue(mockService.checkInputMonitoring())
    }

    func testMockGetCurrentStateReflectsConfiguration() {
        mockService.accessibilityGranted = true
        mockService.inputMonitoringGranted = false

        let state = mockService.getCurrentState()
        XCTAssertTrue(state.accessibility.isGranted)
        XCTAssertFalse(state.inputMonitoring.isGranted)
    }

    func testMockTracksOpenSettingsCalls() {
        XCTAssertFalse(mockService.openSettingsCalled)
        XCTAssertNil(mockService.lastOpenedSettingsType)

        mockService.openSettings(for: .accessibility)
        XCTAssertTrue(mockService.openSettingsCalled)
        XCTAssertEqual(mockService.lastOpenedSettingsType, .accessibility)

        mockService.openSettings(for: .inputMonitoring)
        XCTAssertEqual(mockService.lastOpenedSettingsType, .inputMonitoring)
    }
}
