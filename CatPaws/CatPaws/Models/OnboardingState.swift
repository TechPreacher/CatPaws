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
    case grantPermission = 2
    case testDetection = 3
    case complete = 4

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
}

/// Tracks first-run onboarding completion state
struct OnboardingState {
    // MARK: - Keys

    private static let completedKey = "catpaws.onboarding.completed"
    private static let skippedKey = "catpaws.onboarding.skipped"

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

    // MARK: - In-Memory State

    /// Current step in the onboarding flow (not persisted)
    var currentStep: OnboardingStep = .welcome

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
    }
}
