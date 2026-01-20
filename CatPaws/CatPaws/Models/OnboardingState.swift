//
//  OnboardingState.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import Foundation

/// Represents the steps in the first-run onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissionExplanation = 1
    case grantAccessibility = 2
    case grantInputMonitoring = 3
    case testDetection = 4
    case complete = 5

    /// Returns the next step, or nil if at the end
    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    /// Returns the previous step, or nil if at the beginning
    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    /// Whether this is the final step
    var isFinal: Bool {
        self == .complete
    }

    /// Whether this step involves granting a permission
    var isPermissionStep: Bool {
        self == .grantAccessibility || self == .grantInputMonitoring
    }
}

/// Tracks first-run onboarding completion state
struct OnboardingState {
    // MARK: - Keys

    private static let completedKey = "catpaws.onboarding.completed"
    private static let skippedKey = "catpaws.onboarding.skipped"
    private static let currentStepKey = "catpaws.onboarding.currentStep"
    private static let migrationKey = "catpaws.onboarding.v2Migration"

    // MARK: - Persisted Properties

    /// True after user finishes or skips onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.completedKey) }
    }

    /// True if user skipped instead of completing all steps
    var wasSkipped: Bool {
        get { UserDefaults.standard.bool(forKey: Self.skippedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.skippedKey) }
    }

    /// Current step in the onboarding flow (persisted to resume after restart)
    var currentStep: OnboardingStep {
        get {
            let rawValue = UserDefaults.standard.integer(forKey: Self.currentStepKey)
            return OnboardingStep(rawValue: rawValue) ?? .welcome
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.currentStepKey)
        }
    }

    // MARK: - State Transitions

    /// Marks onboarding as complete
    mutating func complete() {
        hasCompletedOnboarding = true
    }

    /// Marks onboarding as skipped
    mutating func skip() {
        hasCompletedOnboarding = true
        wasSkipped = true
    }

    /// Advances to the next step if available
    /// - Returns: true if advanced, false if already at end
    @discardableResult
    mutating func advance() -> Bool {
        guard let next = currentStep.next else { return false }
        currentStep = next
        return true
    }

    /// Goes back to the previous step if available
    /// - Returns: true if went back, false if already at start
    @discardableResult
    mutating func goBack() -> Bool {
        guard let previous = currentStep.previous else { return false }
        currentStep = previous
        return true
    }

    // MARK: - Testing Support

    /// Resets onboarding state for testing purposes
    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: completedKey)
        UserDefaults.standard.removeObject(forKey: skippedKey)
        UserDefaults.standard.removeObject(forKey: currentStepKey)
    }

    // MARK: - Migration

    /// Migrates step values for users who were mid-onboarding when the new Accessibility step was added.
    /// Users with persisted step >= 2 (old grantPermission) need their step incremented by 1
    /// to account for the new grantAccessibility step inserted at position 2.
    static func migrateIfNeeded() {
        let defaults = UserDefaults.standard

        // Skip if already migrated
        guard !defaults.bool(forKey: migrationKey) else { return }

        let currentRaw = defaults.integer(forKey: currentStepKey)

        // If user was on grantPermission (2) or later, increment to account for new step
        if currentRaw >= 2 {
            defaults.set(currentRaw + 1, forKey: currentStepKey)
        }

        // Mark migration as complete
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - Reset

    /// Clears all onboarding state (for reset functionality)
    mutating func reset() {
        UserDefaults.standard.removeObject(forKey: Self.completedKey)
        UserDefaults.standard.removeObject(forKey: Self.skippedKey)
        UserDefaults.standard.removeObject(forKey: Self.currentStepKey)
        // Note: We don't remove migrationKey - migration should only run once per install
    }
}
