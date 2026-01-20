//
//  PermissionStatusTests.swift
//  CatPawsTests
//
//  Created on 2026-01-19.
//

import XCTest
@testable import CatPaws

final class PermissionStatusTests: XCTestCase {
    // MARK: - PermissionStatus Tests

    func testPermissionStatusInitialization() {
        let status = PermissionStatus(type: .accessibility, isGranted: true)
        XCTAssertEqual(status.type, .accessibility)
        XCTAssertTrue(status.isGranted)
    }

    func testPermissionStatusDisplayName() {
        let accessibilityStatus = PermissionStatus(type: .accessibility, isGranted: false)
        XCTAssertEqual(accessibilityStatus.displayName, "Accessibility")

        let inputMonitoringStatus = PermissionStatus(type: .inputMonitoring, isGranted: false)
        XCTAssertEqual(inputMonitoringStatus.displayName, "Input Monitoring")
    }

    func testPermissionStatusTextWhenGranted() {
        let status = PermissionStatus(type: .accessibility, isGranted: true)
        XCTAssertEqual(status.statusText, "OK")
    }

    func testPermissionStatusTextWhenNotGranted() {
        let status = PermissionStatus(type: .accessibility, isGranted: false)
        XCTAssertEqual(status.statusText, "Needs Permission")
    }

    func testPermissionStatusSettingsURL() {
        let accessibilityStatus = PermissionStatus(type: .accessibility, isGranted: false)
        XCTAssertEqual(accessibilityStatus.settingsURL, PermissionType.accessibility.settingsURL)

        let inputMonitoringStatus = PermissionStatus(type: .inputMonitoring, isGranted: false)
        XCTAssertEqual(inputMonitoringStatus.settingsURL, PermissionType.inputMonitoring.settingsURL)
    }

    func testPermissionStatusEquality() {
        let status1 = PermissionStatus(type: .accessibility, isGranted: true)
        let status2 = PermissionStatus(type: .accessibility, isGranted: true)
        let status3 = PermissionStatus(type: .accessibility, isGranted: false)
        let status4 = PermissionStatus(type: .inputMonitoring, isGranted: true)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
        XCTAssertNotEqual(status1, status4)
    }

    // MARK: - PermissionState Tests

    func testPermissionStateDefaultInitialization() {
        let state = PermissionState()
        XCTAssertFalse(state.accessibility.isGranted)
        XCTAssertFalse(state.inputMonitoring.isGranted)
        XCTAssertEqual(state.accessibility.type, .accessibility)
        XCTAssertEqual(state.inputMonitoring.type, .inputMonitoring)
    }

    func testPermissionStateCustomInitialization() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: true),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: true)
        )
        XCTAssertTrue(state.accessibility.isGranted)
        XCTAssertTrue(state.inputMonitoring.isGranted)
    }

    func testAllGrantedWhenBothGranted() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: true),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: true)
        )
        XCTAssertTrue(state.allGranted)
        XCTAssertFalse(state.anyMissing)
    }

    func testAllGrantedWhenNoneGranted() {
        let state = PermissionState()
        XCTAssertFalse(state.allGranted)
        XCTAssertTrue(state.anyMissing)
    }

    func testAllGrantedWhenOnlyAccessibilityGranted() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: true),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: false)
        )
        XCTAssertFalse(state.allGranted)
        XCTAssertTrue(state.anyMissing)
    }

    func testAllGrantedWhenOnlyInputMonitoringGranted() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: false),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: true)
        )
        XCTAssertFalse(state.allGranted)
        XCTAssertTrue(state.anyMissing)
    }

    func testOnlyAccessibilityMissing() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: false),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: true)
        )
        XCTAssertTrue(state.onlyAccessibilityMissing)
        XCTAssertFalse(state.onlyInputMonitoringMissing)
    }

    func testOnlyInputMonitoringMissing() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: true),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: false)
        )
        XCTAssertFalse(state.onlyAccessibilityMissing)
        XCTAssertTrue(state.onlyInputMonitoringMissing)
    }

    func testNeitherOnlyMissingWhenBothMissing() {
        let state = PermissionState()
        XCTAssertFalse(state.onlyAccessibilityMissing)
        XCTAssertFalse(state.onlyInputMonitoringMissing)
    }

    func testNeitherOnlyMissingWhenBothGranted() {
        let state = PermissionState(
            accessibility: PermissionStatus(type: .accessibility, isGranted: true),
            inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: true)
        )
        XCTAssertFalse(state.onlyAccessibilityMissing)
        XCTAssertFalse(state.onlyInputMonitoringMissing)
    }

    func testUpdateChangesState() {
        let state = PermissionState()
        XCTAssertFalse(state.accessibility.isGranted)
        XCTAssertFalse(state.inputMonitoring.isGranted)

        state.update(accessibilityGranted: true, inputMonitoringGranted: false)
        XCTAssertTrue(state.accessibility.isGranted)
        XCTAssertFalse(state.inputMonitoring.isGranted)

        state.update(accessibilityGranted: true, inputMonitoringGranted: true)
        XCTAssertTrue(state.accessibility.isGranted)
        XCTAssertTrue(state.inputMonitoring.isGranted)
    }
}
