//
//  MenuBarContentView.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import SwiftUI

/// Content view displayed in the menu bar extra window
struct MenuBarContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: viewModel.iconState.systemImageName)
                    .font(.title)
                    .foregroundColor(viewModel.iconState.isGrayed ? .gray : .accentColor)

                Text("CatPaws")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            Divider()

            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.appState.isActive },
                    set: { _ in viewModel.toggleActive() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            // Permission warning
            if !viewModel.hasPermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)

                    Text("Input Monitoring permission required")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Grant") {
                        viewModel.openPermissionSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            // Manual unlock button (shown when locked)
            if viewModel.isLocked {
                Button(
                    action: { viewModel.manualUnlock() },
                    label: {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Unlock Keyboard")
                        }
                        .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            Spacer()

            // Footer
            HStack {
                SettingsLink {
                    Text("Settings")
                }
                .buttonStyle(.link)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .frame(width: 280, height: viewModel.isLocked || !viewModel.hasPermission ? 240 : 180)
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        if viewModel.isLocked {
            return .orange
        } else if viewModel.appState.isActive {
            return .green
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if viewModel.isLocked {
            return "Keyboard Locked"
        } else if viewModel.appState.isActive {
            return "Active"
        } else {
            return "Inactive"
        }
    }
}

#Preview {
    MenuBarContentView(viewModel: AppViewModel())
}
