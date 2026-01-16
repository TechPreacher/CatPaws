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
            Keys.playSoundOnUnlock: Defaults.playSoundOnUnlock
        ])
    }

    // MARK: - ConfigurationProviding

    @Published var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    @Published var debounceMs: Int {
        get {
            let value = defaults.integer(forKey: Keys.debounceMs)
            return Ranges.debounceMs.contains(value) ? value : Defaults.debounceMs
        }
        set {
            let clamped = min(max(newValue, Ranges.debounceMs.lowerBound), Ranges.debounceMs.upperBound)
            defaults.set(clamped, forKey: Keys.debounceMs)
        }
    }

    @Published var recheckIntervalSec: Double {
        get {
            let value = defaults.double(forKey: Keys.recheckIntervalSec)
            return Ranges.recheckIntervalSec.contains(value) ? value : Defaults.recheckIntervalSec
        }
        set {
            let clamped = min(max(newValue, Ranges.recheckIntervalSec.lowerBound), Ranges.recheckIntervalSec.upperBound)
            defaults.set(clamped, forKey: Keys.recheckIntervalSec)
        }
    }

    @Published var cooldownSec: Double {
        get {
            let value = defaults.double(forKey: Keys.cooldownSec)
            return Ranges.cooldownSec.contains(value) ? value : Defaults.cooldownSec
        }
        set {
            let clamped = min(max(newValue, Ranges.cooldownSec.lowerBound), Ranges.cooldownSec.upperBound)
            defaults.set(clamped, forKey: Keys.cooldownSec)
        }
    }

    @Published var minimumKeyCount: Int {
        get {
            let value = defaults.integer(forKey: Keys.minimumKeyCount)
            return Ranges.minimumKeyCount.contains(value) ? value : Defaults.minimumKeyCount
        }
        set {
            let clamped = min(max(newValue, Ranges.minimumKeyCount.lowerBound), Ranges.minimumKeyCount.upperBound)
            defaults.set(clamped, forKey: Keys.minimumKeyCount)
        }
    }

    @Published var playSoundOnLock: Bool {
        get { defaults.bool(forKey: Keys.playSoundOnLock) }
        set { defaults.set(newValue, forKey: Keys.playSoundOnLock) }
    }

    @Published var playSoundOnUnlock: Bool {
        get { defaults.bool(forKey: Keys.playSoundOnUnlock) }
        set { defaults.set(newValue, forKey: Keys.playSoundOnUnlock) }
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
