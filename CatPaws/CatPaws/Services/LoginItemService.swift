//
//  LoginItemService.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation
import ServiceManagement

/// Service for managing the app's login item status using SMAppService
final class LoginItemService: ObservableObject {
    static let shared = LoginItemService()

    @Published private(set) var lastError: Error?

    private init() {}

    // MARK: - Status

    /// Whether the app is currently registered as a login item
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// The current status of the login item registration
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    // MARK: - Registration

    /// Register the app as a login item
    /// - Throws: An error if registration fails
    func register() throws {
        do {
            try SMAppService.mainApp.register()
            lastError = nil
            objectWillChange.send()
        } catch {
            lastError = error
            objectWillChange.send()
            throw error
        }
    }

    /// Unregister the app from login items
    /// - Throws: An error if unregistration fails
    func unregister() throws {
        do {
            try SMAppService.mainApp.unregister()
            lastError = nil
            objectWillChange.send()
        } catch {
            lastError = error
            objectWillChange.send()
            throw error
        }
    }

    /// Toggle the login item status
    /// - Parameter enabled: Whether the app should launch at login
    /// - Throws: An error if the toggle operation fails
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try register()
        } else {
            try unregister()
        }
    }
}
