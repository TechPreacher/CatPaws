//
//  PermissionGuideView.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import SwiftUI
import AppKit

/// View that guides users through granting Input Monitoring permission
struct PermissionGuideView: View {
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Warning icon
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            // Title
            Text("Permission Required")
                .font(.headline)
                .fontWeight(.semibold)

            // Explanation
            Text("CatPaws needs Input Monitoring permission to detect when your cat walks on the keyboard.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Steps
            VStack(alignment: .leading, spacing: 8) {
                PermissionStepRow(number: 1, text: "Click \"Open System Settings\" below")
                PermissionStepRow(number: 2, text: "Find CatPaws in the list")
                PermissionStepRow(number: 3, text: "Toggle CatPaws ON")
            }
            .padding(.vertical, 8)

            // Open Settings button
            Button(action: onOpenSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open System Settings")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Quit button
            Button("Quit CatPaws") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.link)
        }
        .padding()
    }

    /// Open System Settings directly to Input Monitoring pane
    static func openInputMonitoringSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        guard let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

/// A row showing a numbered step in the permission guide
private struct PermissionStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    PermissionGuideView(onOpenSettings: {})
        .frame(width: 280)
}
