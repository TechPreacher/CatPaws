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
        .frame(width: 450, height: 320)
    }
}

/// General settings tab content
struct GeneralSettingsView: View {
    @ObservedObject private var loginItemService = LoginItemService.shared
    @State private var showingError = false
    @State private var errorMessage = ""

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
            Toggle("Launch at login", isOn: launchAtLoginBinding)
        }
        .padding()
        .alert("Login Item Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

/// Detection settings tab content
struct DetectionSettingsView: View {
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
                    Slider(value: Binding(
                        get: { Double(configuration.debounceMs) },
                        set: { configuration.debounceMs = Int($0) }
                    ), in: 200...500, step: 50)
                    .frame(width: 150)
                    Text("\(configuration.debounceMs)ms")
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Auto-Unlock") {
                HStack {
                    Text("Re-check interval:")
                    Spacer()
                    Slider(value: $configuration.recheckIntervalSec, in: 1...5, step: 0.5)
                        .frame(width: 150)
                    Text(String(format: "%.1fs", configuration.recheckIntervalSec))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }

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
struct AboutView: View {
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
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
