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
        static let debounceMs = "catpaws.debounceMs"
        static let recheckIntervalSec = "catpaws.recheckIntervalSec"
        static let cooldownSec = "catpaws.cooldownSec"
        static let minimumKeyCount = "catpaws.minimumKeyCount"
        static let playSoundOnLock = "catpaws.playSoundOnLock"
        static let playSoundOnUnlock = "catpaws.playSoundOnUnlock"
        static let launchAtLogin = "catpaws.launchAtLogin"
        static let debugLoggingEnabled = "catpaws.debugLogging"
    }

    // MARK: - Defaults

    private enum Defaults {
        static let isEnabled = true
        static let debounceMs = 300  // Middle of 200-500 range
        static let recheckIntervalSec = 2.0
        static let cooldownSec = 7.0  // Middle of 5-10 range
        static let minimumKeyCount = 3
        static let playSoundOnLock = true
        static let playSoundOnUnlock = true
        static let launchAtLogin = false
        static let debugLoggingEnabled = false
    }

    // MARK: - Ranges

    private enum Ranges {
        static let debounceMs = 200...500
        static let recheckIntervalSec = 1.0...5.0
        static let cooldownSec = 5.0...10.0
        static let minimumKeyCount = 3...5
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.isEnabled: Defaults.isEnabled,
            Keys.debounceMs: Defaults.debounceMs,
            Keys.recheckIntervalSec: Defaults.recheckIntervalSec,
            Keys.cooldownSec: Defaults.cooldownSec,
            Keys.minimumKeyCount: Defaults.minimumKeyCount,
            Keys.playSoundOnLock: Defaults.playSoundOnLock,
            Keys.playSoundOnUnlock: Defaults.playSoundOnUnlock,
            Keys.launchAtLogin: Defaults.launchAtLogin,
            Keys.debugLoggingEnabled: Defaults.debugLoggingEnabled
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

    var recheckIntervalSec: Double {
        get {
            let value = defaults.double(forKey: Keys.recheckIntervalSec)
            return Ranges.recheckIntervalSec.contains(value) ? value : Defaults.recheckIntervalSec
        }
        set {
            objectWillChange.send()
            let clamped = min(max(newValue, Ranges.recheckIntervalSec.lowerBound), Ranges.recheckIntervalSec.upperBound)
            defaults.set(clamped, forKey: Keys.recheckIntervalSec)
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

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.launchAtLogin)
        }
    }

    var debugLoggingEnabled: Bool {
        get { defaults.bool(forKey: Keys.debugLoggingEnabled) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Keys.debugLoggingEnabled)
        }
    }

    func resetToDefaults() {
        isEnabled = Defaults.isEnabled
        debounceMs = Defaults.debounceMs
        recheckIntervalSec = Defaults.recheckIntervalSec
        cooldownSec = Defaults.cooldownSec
        minimumKeyCount = Defaults.minimumKeyCount
        playSoundOnLock = Defaults.playSoundOnLock
        playSoundOnUnlock = Defaults.playSoundOnUnlock
    }
}
