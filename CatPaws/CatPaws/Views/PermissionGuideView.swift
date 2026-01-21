//
//  PermissionGuideView.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import AppKit
import SwiftUI

/// View that displays permission status and guides users through granting permissions
struct PermissionGuideView: View {
    let permissionState: PermissionState
    var onOpenSettings: (PermissionType) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Warning icon
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            // Title
            Text("Permissions Required")
                .font(.headline)
                .fontWeight(.semibold)

            // Permission status rows
            VStack(spacing: 12) {
                PermissionStatusRow(
                    permission: permissionState.accessibility,
                    onOpenSettings: { onOpenSettings(.accessibility) }
                )

                PermissionStatusRow(
                    permission: permissionState.inputMonitoring,
                    onOpenSettings: { onOpenSettings(.inputMonitoring) }
                )
            }
            .padding(.vertical, 8)

            // Instructions for missing permissions
            if permissionState.anyMissing {
                Text("Click \"Open Settings\" next to each missing permission to grant access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
    }

    /// Open System Settings directly to Input Monitoring pane
    static func openInputMonitoringSettings() {
        PermissionService.shared.openSettings(for: .inputMonitoring)
    }

    /// Open System Settings directly to Accessibility pane
    static func openAccessibilitySettings() {
        PermissionService.shared.openSettings(for: .accessibility)
    }
}

/// A row showing the status of a single permission with action button
private struct PermissionStatusRow: View {
    let permission: PermissionStatus
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Permission icon
            Image(systemName: permission.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(permission.isGranted ? .green : .red)

            // Permission name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(permission.displayName)

                Text(permission.statusText)
                    .font(.caption)
                    .foregroundColor(permission.isGranted ? .green : .orange)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(permission.statusText)
            }

            Spacer()

            // Open Settings button (only shown if permission not granted)
            if !permission.isGranted {
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Opens System Settings to grant \(permission.displayName) permission")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    let state = PermissionState(
        accessibility: PermissionStatus(type: .accessibility, isGranted: true),
        inputMonitoring: PermissionStatus(type: .inputMonitoring, isGranted: false)
    )
    return PermissionGuideView(
        permissionState: state,
        onOpenSettings: { _ in }
    )
    .frame(width: 320)
}
