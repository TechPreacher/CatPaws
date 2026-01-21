//
//  SettingsView.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import SwiftUI

/// Settings view for configuring app preferences
struct SettingsView: View {
    @StateObject private var configuration = Configuration()

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            DetectionSettingsView(configuration: configuration)
                .tabItem {
                    Label("Detection", systemImage: "pawprint")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 400)
    }
}

/// General settings tab content
private struct GeneralSettingsView: View {
    @ObservedObject private var loginItemService = LoginItemService.shared
    @StateObject private var statisticsService = StatisticsService()
    @StateObject private var configuration = Configuration()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingResetConfirmation = false
    @State private var showingResetAllConfirmation = false

    /// Whether onboarding is currently in progress (disables reset all)
    private var isOnboardingInProgress: Bool {
        let state = OnboardingState()
        return !state.hasCompletedOnboarding
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { loginItemService.isEnabled },
            set: { newValue in
                do {
                    try loginItemService.setEnabled(newValue)
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            }

            Section("Statistics") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total blocks: \(statisticsService.statistics.totalBlocks)")
                            .font(.subheadline)
                        Text("Today: \(statisticsService.statistics.todayBlocks)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Reset Statistics") {
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Advanced") {
                Toggle("Enable debug logging", isOn: $configuration.debugLoggingEnabled)
                Text("View logs in Console.app with filter: subsystem:com.corti.CatPaws")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Reset") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reset All Settings")
                            .font(.subheadline)
                        Text("Restores factory defaults and clears onboarding.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Reset All…", role: .destructive) {
                        showingResetAllConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(isOnboardingInProgress)
                    .help(isOnboardingInProgress
                          ? "Reset is disabled during onboarding"
                          : "Reset all app settings to factory defaults")
                }
            }
        }
        .padding()
        .alert("Login Item Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Reset Statistics?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                statisticsService.resetAll()
            }
        } message: {
            Text("This will reset all protection statistics to zero. This action cannot be undone.")
        }
        .alert("Reset All Settings?", isPresented: $showingResetAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset All", role: .destructive) {
                configuration.resetAll()
                // Quit the app after reset so onboarding can run on next launch
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            }
        } message: {
            // swiftlint:disable:next line_length
            Text("This will reset all settings to factory defaults and clear onboarding progress. The app will quit and you will need to complete onboarding again on next launch. This action cannot be undone.")
        }
    }
}

/// Detection settings tab content
private struct DetectionSettingsView: View {
    @ObservedObject var configuration: Configuration

    var body: some View {
        Form {
            Section("Detection Sensitivity") {
                HStack {
                    Text("Minimum keys to trigger:")
                    Spacer()
                    Picker("", selection: $configuration.minimumKeyCount) {
                        Text("3 keys").tag(3)
                        Text("4 keys").tag(4)
                        Text("5 keys").tag(5)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                HStack {
                    Text("Debounce time:")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { Double(configuration.debounceMs) },
                            set: { configuration.debounceMs = Int($0) }
                        ),
                        in: 100...500,
                        step: 50
                    )
                    .frame(width: 150)
                    Text("\(configuration.debounceMs)ms")
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Detection time window:")
                        Spacer()
                        Slider(
                            value: Binding(
                                get: { Double(configuration.detectionTimeWindowMs) },
                                set: { configuration.detectionTimeWindowMs = Int($0) }
                            ),
                            in: 100...500,
                            step: 50
                        )
                        .frame(width: 150)
                        Text("\(configuration.detectionTimeWindowMs)ms")
                            .frame(width: 60, alignment: .trailing)
                            .monospacedDigit()
                    }
                    Text("Time window for detecting rapid sequential key presses (e.g., cat paw)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Unlock Behavior") {
                HStack {
                    Text("Cooldown after unlock:")
                    Spacer()
                    Slider(value: $configuration.cooldownSec, in: 5...10, step: 1)
                        .frame(width: 150)
                    Text(String(format: "%.0fs", configuration.cooldownSec))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Sounds") {
                Toggle("Play sound when locked", isOn: $configuration.playSoundOnLock)
                Toggle("Play sound when unlocked", isOn: $configuration.playSoundOnUnlock)
            }

            Section {
                Button("Reset to Defaults") {
                    configuration.resetToDefaults()
                }
            }
        }
        .padding()
    }
}

/// About tab content
private struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("CatPaws")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Protects your keyboard from curious cats")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://catpaws.corti.com")!) {
                    Label("Website", systemImage: "globe")
                }

                Link(destination: URL(string: "https://catpaws.corti.com/privacy-policy.html")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
            .font(.subheadline)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
