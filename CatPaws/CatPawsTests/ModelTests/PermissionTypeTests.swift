//
//  PermissionTypeTests.swift
//  CatPawsTests
//
//  Created on 2026-01-19.
//

import XCTest
@testable import CatPaws

final class PermissionTypeTests: XCTestCase {
    // MARK: - Raw Value Tests

    func testAllCasesExist() {
        let allCases = PermissionType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.accessibility))
        XCTAssertTrue(allCases.contains(.inputMonitoring))
    }

    func testRawValues() {
        XCTAssertEqual(PermissionType.accessibility.rawValue, "accessibility")
        XCTAssertEqual(PermissionType.inputMonitoring.rawValue, "inputMonitoring")
    }

    // MARK: - Display Name Tests

    func testAccessibilityDisplayName() {
        XCTAssertEqual(PermissionType.accessibility.displayName, "Accessibility")
    }

    func testInputMonitoringDisplayName() {
        XCTAssertEqual(PermissionType.inputMonitoring.displayName, "Input Monitoring")
    }

    // MARK: - Settings URL Tests

    func testAccessibilitySettingsURL() {
        let url = PermissionType.accessibility.settingsURL
        XCTAssertEqual(
            url.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }

    func testInputMonitoringSettingsURL() {
        let url = PermissionType.inputMonitoring.settingsURL
        XCTAssertEqual(
            url.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        )
    }

    func testSettingsURLsAreValid() {
        // Both URLs should be non-nil and have the correct scheme
        for permissionType in PermissionType.allCases {
            let url = permissionType.settingsURL
            XCTAssertEqual(url.scheme, "x-apple.systempreferences")
        }
    }

    // MARK: - Explanation Tests

    func testAccessibilityExplanation() {
        let explanation = PermissionType.accessibility.explanation
        XCTAssertFalse(explanation.isEmpty)
        XCTAssertTrue(explanation.contains("keyboard"))
        XCTAssertTrue(explanation.contains("cat"))
    }

    func testInputMonitoringExplanation() {
        let explanation = PermissionType.inputMonitoring.explanation
        XCTAssertFalse(explanation.isEmpty)
        XCTAssertTrue(explanation.contains("keyboard"))
        XCTAssertTrue(explanation.contains("block"))
    }

    func testAllTypesHaveExplanations() {
        for permissionType in PermissionType.allCases {
            XCTAssertFalse(permissionType.explanation.isEmpty)
        }
    }
}
