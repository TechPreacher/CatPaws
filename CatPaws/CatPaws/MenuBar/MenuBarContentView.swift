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
    @State private var showingStatistics = false

    var body: some View {
        VStack(spacing: 16) {
            // Permission revocation banner (shown at top when permission was revoked)
            if viewModel.showPermissionRevokedBanner {
                PermissionRevokedBanner(
                    onOpenSettings: {
                        if !viewModel.permissionState.accessibility.isGranted {
                            viewModel.openSettings(for: .accessibility)
                        } else {
                            viewModel.openSettings(for: .inputMonitoring)
                        }
                    },
                    onDismiss: {
                        viewModel.dismissPermissionRevokedBanner()
                    }
                )
            }

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

            // Permission guide (shown when any permission is missing)
            if viewModel.permissionState.anyMissing {
                PermissionGuideView(
                    permissionState: viewModel.permissionState,
                    onOpenSettings: { type in
                        viewModel.openSettings(for: type)
                    }
                )
            }

            // Statistics summary (when all permissions granted and not showing detailed view)
            if viewModel.permissionState.allGranted && !showingStatistics {
                StatisticsSummaryView(statisticsService: viewModel.statisticsService)
                    .onTapGesture {
                        withAnimation {
                            showingStatistics = true
                        }
                    }
            }

            // Detailed statistics view
            if showingStatistics {
                StatisticsView(statisticsService: viewModel.statisticsService)

                Button("Hide Statistics") {
                    withAnimation {
                        showingStatistics = false
                    }
                }
                .buttonStyle(.link)
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
        .frame(width: 320)
        .frame(minHeight: 400)
        .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Permission Revoked Banner

/// Non-modal banner shown when a permission is revoked during runtime
private struct PermissionRevokedBanner: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Permission Revoked")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("A required permission was removed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Button("Open Settings") {
                onOpenSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss banner")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MenuBarContentView(viewModel: AppViewModel())
}
