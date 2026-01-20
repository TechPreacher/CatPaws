//
//  ConfigurationProviding.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Protocol for reading/writing user configuration
protocol ConfigurationProviding {
    /// Whether cat detection is enabled
    var isEnabled: Bool { get set }

    /// Debounce period in milliseconds (200-500)
    var debounceMs: Int { get set }

    /// Cooldown period in seconds after manual unlock (5-10)
    var cooldownSec: Double { get set }

    /// Minimum adjacent keys to trigger detection (3-5)
    var minimumKeyCount: Int { get set }

    /// Play sound when keyboard locks
    var playSoundOnLock: Bool { get set }

    /// Play sound when keyboard unlocks
    var playSoundOnUnlock: Bool { get set }

    /// Reset all settings to defaults
    func resetToDefaults()
}
