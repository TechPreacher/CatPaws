//
//  AppViewModelTests.swift
//  CatPawsTests
//
//  Created on 2026-01-15.
//

import XCTest
@testable import CatPaws

@MainActor
final class AppViewModelTests: XCTestCase {
    var viewModel: AppViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AppViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.appState.isActive, "App should start inactive")
    }

    func testToggleActive() {
        XCTAssertFalse(viewModel.appState.isActive)
        viewModel.toggleActive()
        XCTAssertTrue(viewModel.appState.isActive)
        viewModel.toggleActive()
        XCTAssertFalse(viewModel.appState.isActive)
    }

    func testResetState() {
        viewModel.appState.isActive = true
        viewModel.resetState()
        XCTAssertFalse(viewModel.appState.isActive)
    }
}
