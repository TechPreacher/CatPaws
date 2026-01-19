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

            // Permission guide (shown when permission not granted)
            if !viewModel.hasPermission {
                PermissionGuideView(onOpenSettings: {
                    viewModel.openPermissionSettings()
                })
            }

            // Statistics summary (when permission granted and not showing detailed view)
            if viewModel.hasPermission && !showingStatistics {
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
        .frame(width: 280, height: calculateHeight())
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

    private func calculateHeight() -> CGFloat {
        var height: CGFloat = 180  // Base height

        if !viewModel.hasPermission {
            height += 200  // Permission guide takes more space
        } else {
            height += 50  // Statistics summary
        }

        if showingStatistics {
            height += 150  // Detailed statistics
        }

        if viewModel.isLocked {
            height += 50  // Unlock button
        }

        return height
    }
}

#Preview {
    MenuBarContentView(viewModel: AppViewModel())
}
