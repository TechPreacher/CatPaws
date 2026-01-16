//
//  CatLockPopupView.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import SwiftUI

/// SwiftUI view for the keyboard lock notification popup
struct CatLockPopupView: View {
    let detectionType: DetectionType
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .accessibilityLabel(iconAccessibilityLabel)

            // Title
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Dismiss button
            Button(action: onDismiss) {
                Text("Unlock Keyboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Unlock keyboard button")
            .accessibilityHint("Double tap to unlock the keyboard")
        }
        .padding(24)
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Keyboard locked notification")
    }

    // MARK: - Content Properties

    private var iconName: String {
        switch detectionType {
        case .paw:
            return "pawprint.fill"
        case .multiPaw:
            return "pawprint.circle.fill"
        case .sitting:
            return "cat.fill"
        }
    }

    private var iconAccessibilityLabel: String {
        switch detectionType {
        case .paw:
            return "Cat paw detected"
        case .multiPaw:
            return "Multiple cat paws detected"
        case .sitting:
            return "Cat sitting on keyboard"
        }
    }

    private var title: String {
        switch detectionType {
        case .paw:
            return "Cat Paw Detected!"
        case .multiPaw:
            return "Multiple Paws Detected!"
        case .sitting:
            return "Cat on Keyboard!"
        }
    }

    private var message: String {
        switch detectionType {
        case .paw:
            return "Keyboard locked to protect your work from curious paws."
        case .multiPaw:
            return "Multiple paw prints detected. Keyboard locked for safety."
        case .sitting:
            return "Your cat appears to be sitting on the keyboard. Input blocked."
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CatLockPopupView(detectionType: .paw) {}
        CatLockPopupView(detectionType: .multiPaw) {}
        CatLockPopupView(detectionType: .sitting) {}
    }
    .padding()
}
