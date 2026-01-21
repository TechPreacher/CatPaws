//
//  Configuration.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// User-configurable settings stored in UserDefaults
final class Configuration: ConfigurationProviding, ObservableObject {
    private let defaults: UserDefaults

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = "catpaws.isEnabled"
        static let hasUserExplicitlyDisabled = "catpaws.hasUserExplicitlyDisabled"
        static let debounceMs = "catpaws.debounceMs"
        static let cooldownSec = "catpaws.cooldownSec"
        static let minimumKeyCount = "catpaws.minimumKeyCount"
        static let playSoundOnLock = "catpaws.playSoundOnLock"
        static let playSoundOnUnlock = "catpaws.playSoundOnUnlock"
        static let debugLoggingEnabled = "catpaws.debugLogging"
        static let detectionTimeWindowMs = "catpaws.detectionTimeWindowMs"
    }

    // MARK: - Defaults

    private enum Defaults {
        static let isEnabled = true
        static let hasUserExplicitlyDisabled = false
        static let debounceMs = 200  // Lower end for faster response
        static let cooldownSec = 7.0  // Middle of 5-10 range
        static let minimumKeyCount = 3
        static let playSoundOnLock = true
        static let playSoundOnUnlock = true
        static let debugLoggingEnabled = false
        static let detectionTimeWindowMs = 300  // 300ms default for cat paw detection window
    }

    // MARK: - Ranges

    private enum Ranges {
        static let debounceMs = 100...500
        static let cooldownSec = 5.0...10.0
        static let minimumKeyCount = 3...5
        static let detectionTimeWindowMs = 100...500
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.isEnabled: Defaults.isEnabled,
            Keys.hasUserExplicitlyDisabled: Defaults.hasUserExplicitlyDisabled,
            Keys.debounceMs: Defaults.debounceMs,
            Keys.cooldownSec: Defaults.cooldownSec,
            Keys.minimumKeyCount: Defaults.minimumKeyCount,
            Keys.playSoundOnLock: Defaults.playSoundOnLock,
            Keys.playSoundOnUnlock: Defaults.playSoundOnUnlock,
            Keys.debugLoggingEnabled: Defaults.debugLoggingEnabled,
            Keys.detectionTimeWindowMs: Defaults.detectionTimeWindowMs
        ])
    }

    // MARK: - ConfigurationProviding

    var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.isEnabled)
        }
    }

    /// Tracks whether the user has explicitly disabled monitoring.
    /// Used to distinguish between "never configured" (auto-enable) and "user disabled" (respect choice).
    var hasUserExplicitlyDisabled: Bool {
        get { defaults.bool(forKey: Keys.hasUserExplicitlyDisabled) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.hasUserExplicitlyDisabled)
        }
    }

    /// Returns true if monitoring should auto-enable on app start.
    /// Auto-enables unless user has explicitly disabled monitoring.
    var shouldAutoEnable: Bool {
        !hasUserExplicitlyDisabled
    }

    var debounceMs: Int {
        get {
            let value = defaults.integer(forKey: Keys.debounceMs)
            return Ranges.debounceMs.contains(value) ? value : Defaults.debounceMs
        }
        set {
            objectWillChange.send()
            let clamped = min(max(newValue, Ranges.debounceMs.lowerBound), Ranges.debounceMs.upperBound)
            defaults.set(clamped, forKey: Keys.debounceMs)
        }
    }

    var cooldownSec: Double {
        get {
            let value = defaults.double(forKey: Keys.cooldownSec)
            return Ranges.cooldownSec.contains(value) ? value : Defaults.cooldownSec
        }
        set {
            objectWillChange.send()
            let clamped = min(max(newValue, Ranges.cooldownSec.lowerBound), Ranges.cooldownSec.upperBound)
            defaults.set(clamped, forKey: Keys.cooldownSec)
        }
    }

    var minimumKeyCount: Int {
        get {
            let value = defaults.integer(forKey: Keys.minimumKeyCount)
            return Ranges.minimumKeyCount.contains(value) ? value : Defaults.minimumKeyCount
        }
        set {
            objectWillChange.send()
            let clamped = min(max(newValue, Ranges.minimumKeyCount.lowerBound), Ranges.minimumKeyCount.upperBound)
            defaults.set(clamped, forKey: Keys.minimumKeyCount)
        }
    }

    var playSoundOnLock: Bool {
        get { defaults.bool(forKey: Keys.playSoundOnLock) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.playSoundOnLock)
        }
    }

    var playSoundOnUnlock: Bool {
        get { defaults.bool(forKey: Keys.playSoundOnUnlock) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.playSoundOnUnlock)
        }
    }

    var debugLoggingEnabled: Bool {
        get { defaults.bool(forKey: Keys.debugLoggingEnabled) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.debugLoggingEnabled)
        }
    }

    var detectionTimeWindowMs: Int {
        get {
            let value = defaults.integer(forKey: Keys.detectionTimeWindowMs)
            return Ranges.detectionTimeWindowMs.contains(value) ? value : Defaults.detectionTimeWindowMs
        }
        set {
            objectWillChange.send()
            let clamped = min(max(newValue, Ranges.detectionTimeWindowMs.lowerBound), Ranges.detectionTimeWindowMs.upperBound)
            defaults.set(clamped, forKey: Keys.detectionTimeWindowMs)
        }
    }

    func resetToDefaults() {
        isEnabled = Defaults.isEnabled
        debounceMs = Defaults.debounceMs
        cooldownSec = Defaults.cooldownSec
        minimumKeyCount = Defaults.minimumKeyCount
        playSoundOnLock = Defaults.playSoundOnLock
        playSoundOnUnlock = Defaults.playSoundOnUnlock
        detectionTimeWindowMs = Defaults.detectionTimeWindowMs
    }

    /// Resets ALL app settings to factory defaults, including onboarding state.
    /// This will trigger the onboarding flow on next app launch.
    func resetAll() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }

        // Remove all UserDefaults for this app
        defaults.removePersistentDomain(forName: bundleId)
        defaults.synchronize()

        // Re-register default values
        registerDefaults()

        // Notify observers of the change
        objectWillChange.send()
    }
}
