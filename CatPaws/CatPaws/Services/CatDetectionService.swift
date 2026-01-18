//
//  CatDetectionService.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Combine
import Foundation

/// Service that analyzes keyboard state to detect cat paw patterns
final class CatDetectionService: CatDetecting {
    // MARK: - Configuration

    /// Minimum number of adjacent keys to trigger detection (default: 3)
    var minimumKeyCount: Int = 3

    /// Key count threshold for sitting detection (default: 10)
    let sittingThreshold: Int = 10

    // MARK: - Layout Support

    /// The keyboard layout detector for layout-aware detection
    private let layoutDetector: KeyboardLayoutDetecting

    /// Subscription for layout change notifications
    private var layoutSubscription: AnyCancellable?

    /// The current keyboard layout to use for adjacency calculations
    private var currentLayout: KeyboardAdjacencyMap.Layout

    // MARK: - Initialization

    /// Initialize with an optional layout detector
    /// - Parameter layoutDetector: The layout detector to use. Defaults to shared instance.
    init(layoutDetector: KeyboardLayoutDetecting = KeyboardLayoutDetector.shared) {
        self.layoutDetector = layoutDetector
        self.currentLayout = layoutDetector.currentLayout

        // Subscribe to layout changes
        layoutSubscription = layoutDetector.layoutChanged
            .sink { [weak self] newLayout in
                self?.currentLayout = newLayout
            }

        // Start observing layout changes
        if let detector = layoutDetector as? KeyboardLayoutDetector {
            detector.startObserving()
        }
    }

    // MARK: - CatDetecting

    func analyzePattern(pressedKeys: Set<UInt16>) -> DetectionEvent? {
        // Filter out modifier keys
        let nonModifierKeys = KeyboardAdjacencyMap.filterModifiers(from: pressedKeys)

        // Need at least minimumKeyCount non-modifier keys
        guard nonModifierKeys.count >= minimumKeyCount else {
            return nil
        }

        // Check for sitting pattern (10+ keys)
        if nonModifierKeys.count >= sittingThreshold {
            return DetectionEvent(
                type: .sitting,
                keyCount: nonModifierKeys.count
            )
        }

        // Find connected clusters using current layout
        let clusters = findClusters(in: nonModifierKeys, layout: currentLayout)

        // Check for multi-paw pattern (2+ clusters each with 3+ keys)
        let significantClusters = clusters.filter { $0.count >= minimumKeyCount }
        if significantClusters.count >= 2 {
            return DetectionEvent(
                type: .multiPaw,
                keyCount: nonModifierKeys.count
            )
        }

        // Check for single paw pattern (one cluster with 3+ adjacent keys)
        if let largestCluster = clusters.max(by: { $0.count < $1.count }),
           largestCluster.count >= minimumKeyCount {
            return DetectionEvent(
                type: .paw,
                keyCount: largestCluster.count
            )
        }

        return nil
    }

    func formsConnectedCluster(_ keys: Set<UInt16>) -> Bool {
        // Empty set or single key trivially forms a cluster
        guard keys.count > 1 else {
            return true
        }

        // Get key positions for current layout
        let positions = KeyboardAdjacencyMap.keyPositions(for: currentLayout)

        // Filter out any modifiers and unknown keys
        let validKeys = keys.filter { positions[$0] != nil }
        guard validKeys.count > 1 else {
            return keys.count <= 1
        }

        // Use BFS to check connectivity
        var visited: Set<UInt16> = []
        var queue: [UInt16] = []

        // Start from first key
        guard let startKey = validKeys.first else {
            return true
        }

        queue.append(startKey)
        visited.insert(startKey)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            // Find all adjacent keys that are in our set
            for otherKey in validKeys where otherKey != current {
                if !visited.contains(otherKey) &&
                    KeyboardAdjacencyMap.areAdjacent(current, otherKey, layout: currentLayout) {
                    visited.insert(otherKey)
                    queue.append(otherKey)
                }
            }
        }

        // All valid keys should be visited if they form a connected cluster
        return visited.count == validKeys.count
    }

    // MARK: - Private Methods

    /// Find all connected clusters in a set of keys
    /// - Parameters:
    ///   - keys: Set of key codes
    ///   - layout: The keyboard layout to use for adjacency calculations
    /// - Returns: Array of clusters, each cluster is a set of connected keys
    private func findClusters(
        in keys: Set<UInt16>,
        layout: KeyboardAdjacencyMap.Layout
    ) -> [Set<UInt16>] {
        // Get key positions for the specified layout
        let positions = KeyboardAdjacencyMap.keyPositions(for: layout)

        // Filter to only keys with known positions
        let validKeys = keys.filter { positions[$0] != nil }

        guard !validKeys.isEmpty else {
            return []
        }

        var clusters: [Set<UInt16>] = []
        var unvisited = validKeys

        while !unvisited.isEmpty {
            // Start a new cluster from an unvisited key
            guard let startKey = unvisited.first else { break }

            var cluster: Set<UInt16> = []
            var queue: [UInt16] = [startKey]

            while !queue.isEmpty {
                let current = queue.removeFirst()

                guard unvisited.contains(current) else { continue }

                unvisited.remove(current)
                cluster.insert(current)

                // Add all adjacent unvisited keys to queue
                for otherKey in unvisited where KeyboardAdjacencyMap.areAdjacent(current, otherKey, layout: layout) {
                    queue.append(otherKey)
                }
            }

            if !cluster.isEmpty {
                clusters.append(cluster)
            }
        }

        return clusters
    }
}
