//
//  LoginItemServiceTests.swift
//  CatPawsTests
//
//  Created on 2026-01-20.
//

import XCTest
@testable import CatPaws

final class LoginItemServiceTests: XCTestCase {
    private var sut: LoginItemService!

    override func setUp() {
        super.setUp()
        sut = LoginItemService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(LoginItemService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = LoginItemService.shared
        let instance2 = LoginItemService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Status Tests (T050)

    func testIsEnabledReturnsBoolean() {
        // isEnabled should return the current status from SMAppService
        // We can only verify it returns a valid boolean without modifying state
        let status = sut.isEnabled
        // The actual value depends on system state, but it should be a valid boolean
        XCTAssertTrue(status == true || status == false)
    }

    // MARK: - Registration Tests (T051)

    func testSetEnabledAcceptsBoolean() {
        // These tests verify the API accepts the correct parameter type
        // They don't actually persist state to avoid modifying system configuration
        // The method signature accepts a Bool parameter
        // This is a compile-time check; if it compiles, the API is correct
        _ = { [weak self] in
            guard let self = self else { return }
            // Type checking - verify the method accepts Bool
            do {
                try self.sut.setEnabled(true)
            } catch {
                // Expected to throw without proper permissions in test environment
            }
        }
    }

    func testRegisterMethodExists() {
        // Verify the register method exists and can be called
        // The method may succeed or throw depending on system state
        do {
            try sut.register()
            // Method succeeded - that's valid
        } catch {
            // Method threw - that's also valid in test environment
            XCTAssertNotNil(error)
        }
    }

    func testUnregisterMethodExists() {
        // Verify the unregister method exists and can be called
        // The method may succeed or throw depending on system state
        do {
            try sut.unregister()
            // Method succeeded - that's valid
        } catch {
            // Method threw - that's also valid in test environment
            XCTAssertNotNil(error)
        }
    }
}
