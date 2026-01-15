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
                Image(systemName: "pawprint.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)

                Text("CatPaws")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            Divider()

            // Status
            HStack {
                Circle()
                    .fill(viewModel.appState.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(viewModel.appState.isActive ? "Active" : "Inactive")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: $viewModel.appState.isActive)
                    .toggleStyle(.switch)
                    .labelsHidden()
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
        .frame(width: 280, height: 180)
    }
}

#Preview {
    MenuBarContentView(viewModel: AppViewModel())
}
