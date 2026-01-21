//
//  AppStateTests.swift
//  CatPawsTests
//
//  Created on 2026-01-15.
//

import XCTest
@testable import CatPaws

final class AppStateTests: XCTestCase {
    func testDefaultInitialization() {
        let state = AppState()
        XCTAssertFalse(state.isActive)
    }

    func testIsActiveMutation() {
        var state = AppState()
        XCTAssertFalse(state.isActive)
        state.isActive = true
        XCTAssertTrue(state.isActive)
    }
}
