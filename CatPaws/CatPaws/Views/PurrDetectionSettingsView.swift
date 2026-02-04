//
//  PurrDetectionSettingsView.swift
//  CatPaws
//
//  Created on 2026-01-21.
//

import SwiftUI

/// Settings view for purr detection configuration
struct PurrDetectionSettingsView: View {
    @ObservedObject var configuration: Configuration
    @StateObject private var permissionService = PermissionService.shared
    @State private var hasMicrophonePermission: Bool = false

    var body: some View {
        Section("Purr Detection") {
            // Main toggle
            Toggle("Enable purr detection", isOn: $configuration.purrDetectionEnabled)

            // Permission status
            if configuration.purrDetectionEnabled {
                HStack {
                    if hasMicrophonePermission {
                        Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("Microphone access required", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Spacer()

                        Button("Open Settings") {
                            permissionService.openSettings(for: .microphone)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            // Sensitivity slider (only show when enabled)
            if configuration.purrDetectionEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Detection sensitivity:")
                        Spacer()
                        Slider(value: $configuration.purrSensitivity, in: 0...1, step: 0.1)
                            .frame(width: 150)
                        Text(sensitivityLabel)
                            .frame(width: 60, alignment: .trailing)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Higher sensitivity detects quieter purrs but may increase false positives.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sound threshold:")
                        Spacer()
                        Slider(
                            value: Binding(
                                get: { configuration.purrSoundThreshold * 100 },
                                set: { configuration.purrSoundThreshold = $0 / 100 }
                            ),
                            in: 0.1...10,
                            step: 0.1
                        )
                        .frame(width: 150)
                        Text(String(format: "%.1f%%", configuration.purrSoundThreshold * 100))
                            .frame(width: 60, alignment: .trailing)
                            .monospacedDigit()
                    }
                    Text("Minimum audio level to trigger analysis. Lower values detect softer sounds.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            checkMicrophonePermission()
        }
        .onChange(of: configuration.purrDetectionEnabled) { _, isEnabled in
            if isEnabled {
                requestMicrophonePermissionIfNeeded()
            }
        }
    }

    /// Human-readable sensitivity label
    private var sensitivityLabel: String {
        switch configuration.purrSensitivity {
        case 0..<0.3:
            return "Low"
        case 0.3..<0.7:
            return "Medium"
        default:
            return "High"
        }
    }

    /// Check current microphone permission status
    private func checkMicrophonePermission() {
        hasMicrophonePermission = permissionService.checkMicrophone()
    }

    /// Request microphone permission if not already granted
    private func requestMicrophonePermissionIfNeeded() {
        if !hasMicrophonePermission {
            Task {
                let granted = await permissionService.requestMicrophonePermission()
                await MainActor.run {
                    hasMicrophonePermission = granted
                }
            }
        }
    }
}

#Preview {
    Form {
        PurrDetectionSettingsView(configuration: Configuration())
    }
    .frame(width: 480, height: 300)
    .padding()
}
