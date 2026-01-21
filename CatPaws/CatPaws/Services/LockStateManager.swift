//
//  LockStateManager.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import AppKit
import Foundation

/// Delegate for lock state changes
protocol LockStateManagerDelegate: AnyObject {
    /// Called when keyboard should be locked
    func lockStateManagerDidLock(_ manager: LockStateManager)

    /// Called when keyboard should be unlocked
    func lockStateManagerDidUnlock(_ manager: LockStateManager)
}

/// Manages the lock state machine and debounce/cooldown timing
final class LockStateManager: LockStateManaging {
    // MARK: - Properties

    private(set) var state = LockState()

    weak var delegate: LockStateManagerDelegate?

    /// Configuration for timing values
    var configuration: ConfigurationProviding?

    /// The lock service to control
    var lockService: KeyboardLocking?

    /// Notification presenter for showing lock popup
    var notificationPresenter: NotificationPresenting?

    /// Statistics service for recording block events
    var statisticsService: StatisticsService?

    /// Current debounce task
    private var debounceTask: Task<Void, Never>?

    /// Current cooldown task
    private var cooldownTask: Task<Void, Never>?

    /// Pending detection during debounce
    private var pendingDetection: DetectionEvent?

    // MARK: - Computed Properties

    private var debounceMs: Int {
        configuration?.debounceMs ?? 300
    }

    private var cooldownSec: Double {
        configuration?.cooldownSec ?? 7.0
    }

    // MARK: - LockStateManaging

    func handleDetection(_ detection: DetectionEvent) {
        let previousStatus = String(describing: state.status)
        switch state.status {
        case .monitoring:
            // Start debouncing
            pendingDetection = detection
            state.beginDebounce(for: detection)
            AppLogger.logStateTransition(fromState: previousStatus, toState: String(describing: state.status))
            AppLogger.logDebounce()
            startDebounceTimer()

        case .debouncing:
            // Already debouncing, update pending detection
            pendingDetection = detection

        case .locked:
            // Already locked, ignore
            break

        case .cooldown:
            // In cooldown, ignore detection
            break
        }
    }

    func handleKeysReleased() {
        switch state.status {
        case .debouncing:
            // Keys released during debounce, cancel
            cancelDebounce()

        default:
            break
        }
    }

    func manualUnlock() {
        guard state.status == .locked else { return }

        let previousStatus = String(describing: state.status)
        state.manualUnlock(cooldownDuration: cooldownSec)
        AppLogger.logStateTransition(fromState: previousStatus, toState: String(describing: state.status))
        AppLogger.logUnlock(reason: "manual dismiss")
        AppLogger.logCooldown(duration: cooldownSec)
        lockService?.unlock()
        notificationPresenter?.hide()
        delegate?.lockStateManagerDidUnlock(self)

        // Play unlock sound if enabled
        if configuration?.playSoundOnUnlock ?? true {
            playUnlockSound()
        }

        startCooldownTimer()
    }

    // MARK: - Private Methods

    private func startDebounceTimer() {
        debounceTask?.cancel()

        debounceTask = Task { [weak self] in
            guard let self = self else { return }

            let delayMs = UInt64(self.debounceMs) * 1_000_000  // Convert to nanoseconds
            try? await Task.sleep(nanoseconds: delayMs)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.completeDebounce()
            }
        }
    }

    private func cancelDebounce() {
        debounceTask?.cancel()
        debounceTask = nil
        pendingDetection = nil
        state.cancelDebounce()
    }

    private func completeDebounce() {
        guard state.status == .debouncing,
              let detection = pendingDetection else {
            cancelDebounce()
            return
        }

        let previousStatus = String(describing: state.status)
        state.lock(reason: detection)
        AppLogger.logStateTransition(fromState: previousStatus, toState: String(describing: state.status))
        AppLogger.logLock()
        pendingDetection = nil
        lockService?.lock()
        delegate?.lockStateManagerDidLock(self)

        // Record the block for statistics
        statisticsService?.recordBlock()

        // Play lock sound if enabled
        if configuration?.playSoundOnLock ?? true {
            playLockSound()
        }

        // Show notification
        notificationPresenter?.show(detectionType: detection.type) { [weak self] in
            self?.manualUnlock()
        }
    }

    private func startCooldownTimer() {
        cooldownTask?.cancel()

        cooldownTask = Task { [weak self] in
            guard let self = self else { return }

            let delayNs = UInt64(self.cooldownSec * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNs)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.endCooldown()
            }
        }
    }

    private func endCooldown() {
        guard state.status == .cooldown else { return }
        let previousStatus = String(describing: state.status)
        state.endCooldown()
        AppLogger.logStateTransition(fromState: previousStatus, toState: String(describing: state.status))
    }

    // MARK: - Sound Effects

    private func playLockSound() {
        // Use Funk sound for lock - a clear alert tone
        NSSound(named: "Funk")?.play()
    }

    private func playUnlockSound() {
        // Use Pop sound for unlock - a softer, positive tone
        NSSound(named: "Pop")?.play()
    }
}
