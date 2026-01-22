//
//  StatisticsView.swift
//  CatPaws
//
//  Created on 2026-01-18.
//

import SwiftUI

/// Detailed statistics view showing today/week/all-time breakdown
struct StatisticsView: View {
    @ObservedObject var statisticsService: StatisticsService

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("Protection Statistics")
                    .font(.headline)

                Spacer()
            }

            Divider()

            // Keyboard detection statistics grid
            Text("Keyboard Detection")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                StatisticCard(
                    title: "Today",
                    value: statisticsService.statistics.todayBlocks,
                    icon: "sun.max.fill",
                    color: .orange
                )

                StatisticCard(
                    title: "This Week",
                    value: statisticsService.statistics.weekBlocks,
                    icon: "calendar",
                    color: .blue
                )

                StatisticCard(
                    title: "All Time",
                    value: statisticsService.statistics.totalBlocks,
                    icon: "infinity",
                    color: .purple
                )
            }

            // Purr detection statistics
            if statisticsService.statistics.totalPurrDetections > 0 ||
               hasPurrDetectionEnabled {
                Divider()

                Text("Purr Detection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    StatisticCard(
                        title: "Today",
                        value: statisticsService.statistics.todayPurrDetections,
                        icon: "waveform",
                        color: .green
                    )

                    StatisticCard(
                        title: "All Time",
                        value: statisticsService.statistics.totalPurrDetections,
                        icon: "waveform.circle.fill",
                        color: .teal
                    )
                }
            }

            // Last block info
            if let lastBlock = statisticsService.statistics.lastBlockDate {
                HStack {
                    Text("Last protection:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(lastBlock, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("ago")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
        .padding()
    }

    /// Check if purr detection is enabled in configuration
    private var hasPurrDetectionEnabled: Bool {
        Configuration().purrDetectionEnabled
    }
}

/// A card displaying a single statistic
private struct StatisticCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

/// Compact statistics summary for the menu bar
struct StatisticsSummaryView: View {
    @ObservedObject var statisticsService: StatisticsService

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .foregroundColor(.accentColor)

            Text(summaryText)
                .font(.subheadline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
        .contentShape(Rectangle())
    }

    private var summaryText: String {
        let count = statisticsService.statistics.todayBlocks
        if count == 0 {
            return "No blocks today"
        } else if count == 1 {
            return "1 block today"
        } else {
            return "\(count) blocks today"
        }
    }
}

#Preview("StatisticsView") {
    StatisticsView(statisticsService: StatisticsService())
        .frame(width: 300)
}

#Preview("StatisticsSummaryView") {
    StatisticsSummaryView(statisticsService: StatisticsService())
        .frame(width: 280)
        .padding()
}
