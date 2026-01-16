//
//  LockStateManager.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

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

    private(set) var state: LockState = LockState()

    weak var delegate: LockStateManagerDelegate?

    /// Configuration for timing values
    var configuration: ConfigurationProviding?

    /// The lock service to control
    var lockService: KeyboardLocking?

    /// Notification presenter for showing lock popup
    var notificationPresenter: NotificationPresenting?

    /// Current debounce task
    private var debounceTask: Task<Void, Never>?

    /// Current cooldown task
    private var cooldownTask: Task<Void, Never>?

    /// Current recheck task
    private var recheckTask: Task<Void, Never>?

    /// Pending detection during debounce
    private var pendingDetection: DetectionEvent?

    // MARK: - Computed Properties

    private var debounceMs: Int {
        configuration?.debounceMs ?? 300
    }

    private var cooldownSec: Double {
        configuration?.cooldownSec ?? 7.0
    }

    private var recheckIntervalSec: Double {
        configuration?.recheckIntervalSec ?? 2.0
    }

    // MARK: - LockStateManaging

    func handleDetection(_ detection: DetectionEvent) {
        switch state.status {
        case .monitoring:
            // Start debouncing
            pendingDetection = detection
            state.beginDebounce(for: detection)
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

        cancelRecheckTimer()
        state.manualUnlock(cooldownDuration: cooldownSec)
        lockService?.unlock()
        notificationPresenter?.hide()
        delegate?.lockStateManagerDidUnlock(self)

        startCooldownTimer()
    }

    func performRecheck(pressedKeyCount: Int) {
        guard state.status == .locked else { return }

        state.recordRecheck()

        if pressedKeyCount == 0 {
            // No keys pressed, auto-unlock
            autoUnlock()
        }
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

        state.lock(reason: detection)
        pendingDetection = nil
        lockService?.lock()
        delegate?.lockStateManagerDidLock(self)

        // Show notification
        notificationPresenter?.show(detectionType: detection.type) { [weak self] in
            self?.manualUnlock()
        }

        startRecheckTimer()
    }

    private func startRecheckTimer() {
        recheckTask?.cancel()

        recheckTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled && self.state.status == .locked {
                let delayNs = UInt64(self.recheckIntervalSec * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNs)

                guard !Task.isCancelled, self.state.status == .locked else { break }

                // Recheck will be called externally with current key count
                // This timer just ensures periodic checks happen
                await MainActor.run {
                    self.state.recordRecheck()
                }
            }
        }
    }

    private func cancelRecheckTimer() {
        recheckTask?.cancel()
        recheckTask = nil
    }

    private func autoUnlock() {
        cancelRecheckTimer()
        state.autoUnlock()
        lockService?.unlock()
        notificationPresenter?.hide()
        delegate?.lockStateManagerDidUnlock(self)
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
        state.endCooldown()
    }
}
