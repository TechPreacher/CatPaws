//
//  OnboardingView.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import SwiftUI

/// First-run onboarding view with multi-step flow
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressView(currentStep: viewModel.currentStep)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            // Step content
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)

            // Navigation buttons
            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(width: 480, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
        case .permissionExplanation:
            PermissionExplanationStepView()
        case .grantPermission:
            GrantPermissionStepView(
                hasPermission: viewModel.hasPermission,
                onOpenSettings: { viewModel.openPermissionSettings() }
            )
        case .testDetection:
            TestDetectionStepView(
                detectionTriggered: viewModel.detectionTriggered
            )
        case .complete:
            CompleteStepView()
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            // Skip button (shown on all steps except complete)
            if viewModel.currentStep != .complete {
                Button("Skip") {
                    viewModel.skip()
                }
                .buttonStyle(.link)
            }

            Spacer()

            // Back button (not shown on welcome or complete)
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                Button("Back") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }

            // Next/Finish button
            Button(nextButtonTitle) {
                viewModel.nextStep()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isNextDisabled)
        }
    }

    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .welcome, .permissionExplanation:
            return "Next"
        case .grantPermission:
            return viewModel.hasPermission ? "Next" : "Continue Anyway"
        case .testDetection:
            return viewModel.detectionTriggered ? "Finish" : "Skip Test"
        case .complete:
            return "Get Started"
        }
    }

    private var isNextDisabled: Bool {
        false  // All steps can proceed
    }
}

// MARK: - Progress Indicator

private struct OnboardingProgressView: View {
    let currentStep: OnboardingStep

    private let steps: [OnboardingStep] = [
        .welcome, .permissionExplanation, .grantPermission, .testDetection, .complete
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(steps, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Welcome Step (T026)

private struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)

            Text("Welcome to CatPaws")
                .font(.largeTitle)
                .fontWeight(.bold)

            // swiftlint:disable:next line_length
            Text("CatPaws protects your keyboard when your cat decides to take a walk across it. The app detects characteristic cat-paw typing patterns and temporarily locks your keyboard to prevent unwanted input.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Permission Explanation Step (T027)

private struct PermissionExplanationStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("Permission Required")
                .font(.title)
                .fontWeight(.bold)

            // swiftlint:disable:next line_length
            Text("To detect cat paw patterns, CatPaws needs Input Monitoring permission. This allows the app to see when multiple keys are pressed simultaneously.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                PermissionInfoRow(
                    icon: "checkmark.shield.fill",
                    color: .green,
                    text: "Your keystrokes are never recorded or transmitted"
                )
                PermissionInfoRow(
                    icon: "checkmark.shield.fill",
                    color: .green,
                    text: "Only key press patterns are analyzed locally"
                )
                PermissionInfoRow(
                    icon: "checkmark.shield.fill",
                    color: .green,
                    text: "You can revoke permission at any time"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Spacer()
        }
    }
}

private struct PermissionInfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Grant Permission Step (T027 continued)

private struct GrantPermissionStepView: View {
    let hasPermission: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if hasPermission {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Permission Granted!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("CatPaws now has the permission it needs. Click Next to continue.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "gear.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Grant Permission")
                    .font(.title)
                    .fontWeight(.bold)

                // swiftlint:disable:next line_length
                Text("Click the button below to open System Settings, then enable CatPaws in the Input Monitoring list.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onOpenSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open System Settings")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("This page will update automatically when permission is granted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Test Detection Step (T028)

private struct TestDetectionStepView: View {
    let detectionTriggered: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if detectionTriggered {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("It Works!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("CatPaws successfully detected the key pattern. Your keyboard is protected!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "keyboard")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("Test Detection")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Let's make sure CatPaws is working correctly. Press these three keys together:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    KeyCapView(letter: "E")
                    HStack(spacing: 8) {
                        KeyCapView(letter: "S")
                        KeyCapView(letter: "D")
                    }
                }
                .padding(.vertical, 8)

                Text("Press and hold all three keys at the same time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

private struct KeyCapView: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Complete Step

private struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("CatPaws is now running in your menu bar. Look for the paw icon to access settings and status.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .font(.title2)
                Image(systemName: "arrow.right")
                    .font(.caption)
                Image(systemName: "pawprint")
                    .font(.title2)
            }
            .foregroundColor(.secondary)
            .padding()

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
