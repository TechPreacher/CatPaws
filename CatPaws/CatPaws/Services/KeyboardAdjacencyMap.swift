//
//  KeyboardAdjacencyMap.swift
//  CatPaws
//
//  Created on 2026-01-16.
//

import Foundation

/// Provides keyboard layout data and adjacency calculations for cat paw detection
struct KeyboardAdjacencyMap {
    // MARK: - Types

    /// Position of a key on the keyboard in key-width units
    struct KeyPosition {
        let x: Double
        let y: Double
    }

    /// Supported keyboard layout types
    enum Layout: String, CaseIterable {
        case qwerty
        case azerty
        case qwertz
        case dvorak

        /// Detect layout from input source identifier
        /// - Parameter inputSourceId: The TIS input source identifier (e.g., "com.apple.keylayout.French")
        /// - Returns: The detected layout, defaults to QWERTY if unknown
        static func from(inputSourceId: String) -> Layout {
            let lower = inputSourceId.lowercased()
            if lower.contains("french") || lower.contains("azerty") {
                return .azerty
            } else if lower.contains("german") || lower.contains("swiss") || lower.contains("austrian") {
                return .qwertz
            } else if lower.contains("dvorak") {
                return .dvorak
            }
            return .qwerty
        }
    }

    // MARK: - Modifier Key Codes

    /// All modifier key codes (excluded from cat detection)
    static let modifierKeyCodes: Set<UInt16> = [
        0x37,  // Left Command
        0x36,  // Right Command
        0x38,  // Left Shift
        0x3C,  // Right Shift
        0x3A,  // Left Option
        0x3D,  // Right Option
        0x3B,  // Left Control
        0x3E,  // Right Control
        0x3F,  // Function (Fn)
        0x39   // Caps Lock
    ]

    // MARK: - Key Position Map

    /// QWERTY keyboard layout positions (US layout)
    /// Key codes mapped to (x, y) positions in key-width units
    /// Row 0 = number row, Row 1 = QWERTY, Row 2 = ASDF, Row 3 = ZXCV
    static let keyPositions: [UInt16: KeyPosition] = [
        // Row 0: Number row (y = 0)
        0x35: KeyPosition(x: 0, y: 0),     // Escape
        0x12: KeyPosition(x: 1, y: 0),     // 1
        0x13: KeyPosition(x: 2, y: 0),     // 2
        0x14: KeyPosition(x: 3, y: 0),     // 3
        0x15: KeyPosition(x: 4, y: 0),     // 4
        0x17: KeyPosition(x: 5, y: 0),     // 5
        0x16: KeyPosition(x: 6, y: 0),     // 6
        0x1A: KeyPosition(x: 7, y: 0),     // 7
        0x1C: KeyPosition(x: 8, y: 0),     // 8
        0x19: KeyPosition(x: 9, y: 0),     // 9
        0x1D: KeyPosition(x: 10, y: 0),    // 0
        0x1B: KeyPosition(x: 11, y: 0),    // -
        0x18: KeyPosition(x: 12, y: 0),    // =
        0x33: KeyPosition(x: 13.5, y: 0),  // Delete

        // Row 1: QWERTY row (y = 1, offset 0.5 from row 0)
        0x30: KeyPosition(x: 0, y: 1),     // Tab
        0x0C: KeyPosition(x: 1.5, y: 1),   // Q
        0x0D: KeyPosition(x: 2.5, y: 1),   // W
        0x0E: KeyPosition(x: 3.5, y: 1),   // E
        0x0F: KeyPosition(x: 4.5, y: 1),   // R
        0x11: KeyPosition(x: 5.5, y: 1),   // T
        0x10: KeyPosition(x: 6.5, y: 1),   // Y
        0x20: KeyPosition(x: 7.5, y: 1),   // U
        0x22: KeyPosition(x: 8.5, y: 1),   // I
        0x1F: KeyPosition(x: 9.5, y: 1),   // O
        0x23: KeyPosition(x: 10.5, y: 1),  // P
        0x21: KeyPosition(x: 11.5, y: 1),  // [
        0x1E: KeyPosition(x: 12.5, y: 1),  // ]
        0x2A: KeyPosition(x: 13.5, y: 1),  // \

        // Row 2: ASDF row (y = 2, offset 0.75 from row 0)
        0x39: KeyPosition(x: 0, y: 2),     // Caps Lock (also a modifier but has position)
        0x00: KeyPosition(x: 1.75, y: 2),  // A
        0x01: KeyPosition(x: 2.75, y: 2),  // S
        0x02: KeyPosition(x: 3.75, y: 2),  // D
        0x03: KeyPosition(x: 4.75, y: 2),  // F
        0x05: KeyPosition(x: 5.75, y: 2),  // G
        0x04: KeyPosition(x: 6.75, y: 2),  // H
        0x26: KeyPosition(x: 7.75, y: 2),  // J
        0x28: KeyPosition(x: 8.75, y: 2),  // K
        0x25: KeyPosition(x: 9.75, y: 2),  // L
        0x29: KeyPosition(x: 10.75, y: 2), // ;
        0x27: KeyPosition(x: 11.75, y: 2), // '
        0x24: KeyPosition(x: 13, y: 2),    // Return

        // Row 3: ZXCV row (y = 3, offset 1.25 from row 0)
        0x38: KeyPosition(x: 0, y: 3),     // Left Shift (modifier but has position)
        0x06: KeyPosition(x: 2.25, y: 3),  // Z
        0x07: KeyPosition(x: 3.25, y: 3),  // X
        0x08: KeyPosition(x: 4.25, y: 3),  // C
        0x09: KeyPosition(x: 5.25, y: 3),  // V
        0x0B: KeyPosition(x: 6.25, y: 3),  // B
        0x2D: KeyPosition(x: 7.25, y: 3),  // N
        0x2E: KeyPosition(x: 8.25, y: 3),  // M
        0x2B: KeyPosition(x: 9.25, y: 3),  // ,
        0x2F: KeyPosition(x: 10.25, y: 3), // .
        0x2C: KeyPosition(x: 11.25, y: 3), // /
        0x3C: KeyPosition(x: 13, y: 3),    // Right Shift (modifier but has position)

        // Row 4: Bottom row (y = 4)
        0x3B: KeyPosition(x: 0, y: 4),     // Left Control
        0x3A: KeyPosition(x: 1.5, y: 4),   // Left Option
        0x37: KeyPosition(x: 3, y: 4),     // Left Command
        0x31: KeyPosition(x: 6.5, y: 4),   // Space (center, wide key)
        0x36: KeyPosition(x: 10, y: 4),    // Right Command
        0x3D: KeyPosition(x: 11.5, y: 4),  // Right Option
        0x3E: KeyPosition(x: 13, y: 4),    // Right Control

        // Arrow keys (approximate positions)
        0x7B: KeyPosition(x: 14, y: 4),    // Left Arrow
        0x7C: KeyPosition(x: 16, y: 4),    // Right Arrow
        0x7E: KeyPosition(x: 15, y: 3),    // Up Arrow
        0x7D: KeyPosition(x: 15, y: 4)     // Down Arrow
    ]

    // MARK: - AZERTY Key Position Map

    /// AZERTY keyboard layout positions (French layout)
    /// Key codes are the same as QWERTY (hardware-based), but positions differ
    /// Main differences: A↔Q, Z↔W, M moved to right of L
    static let azertyKeyPositions: [UInt16: KeyPosition] = [
        // Row 0: Number row (y = 0) - same as QWERTY
        0x35: KeyPosition(x: 0, y: 0),     // Escape
        0x12: KeyPosition(x: 1, y: 0),     // 1 (&)
        0x13: KeyPosition(x: 2, y: 0),     // 2 (é)
        0x14: KeyPosition(x: 3, y: 0),     // 3 (")
        0x15: KeyPosition(x: 4, y: 0),     // 4 (')
        0x17: KeyPosition(x: 5, y: 0),     // 5 (()
        0x16: KeyPosition(x: 6, y: 0),     // 6 (-)
        0x1A: KeyPosition(x: 7, y: 0),     // 7 (è)
        0x1C: KeyPosition(x: 8, y: 0),     // 8 (_)
        0x19: KeyPosition(x: 9, y: 0),     // 9 (ç)
        0x1D: KeyPosition(x: 10, y: 0),    // 0 (à)
        0x1B: KeyPosition(x: 11, y: 0),    // )
        0x18: KeyPosition(x: 12, y: 0),    // =
        0x33: KeyPosition(x: 13.5, y: 0),  // Delete

        // Row 1: AZERTY row (y = 1) - A and Q swapped, Z and W swapped
        0x30: KeyPosition(x: 0, y: 1),     // Tab
        0x00: KeyPosition(x: 1.5, y: 1),   // A (was Q position)
        0x06: KeyPosition(x: 2.5, y: 1),   // Z (was W position)
        0x0E: KeyPosition(x: 3.5, y: 1),   // E
        0x0F: KeyPosition(x: 4.5, y: 1),   // R
        0x11: KeyPosition(x: 5.5, y: 1),   // T
        0x10: KeyPosition(x: 6.5, y: 1),   // Y
        0x20: KeyPosition(x: 7.5, y: 1),   // U
        0x22: KeyPosition(x: 8.5, y: 1),   // I
        0x1F: KeyPosition(x: 9.5, y: 1),   // O
        0x23: KeyPosition(x: 10.5, y: 1),  // P
        0x21: KeyPosition(x: 11.5, y: 1),  // ^
        0x1E: KeyPosition(x: 12.5, y: 1),  // $
        0x2A: KeyPosition(x: 13.5, y: 1),  // *

        // Row 2: QSDF row (y = 2) - Q and A swapped
        0x39: KeyPosition(x: 0, y: 2),     // Caps Lock
        0x0C: KeyPosition(x: 1.75, y: 2),  // Q (was A position)
        0x01: KeyPosition(x: 2.75, y: 2),  // S
        0x02: KeyPosition(x: 3.75, y: 2),  // D
        0x03: KeyPosition(x: 4.75, y: 2),  // F
        0x05: KeyPosition(x: 5.75, y: 2),  // G
        0x04: KeyPosition(x: 6.75, y: 2),  // H
        0x26: KeyPosition(x: 7.75, y: 2),  // J
        0x28: KeyPosition(x: 8.75, y: 2),  // K
        0x25: KeyPosition(x: 9.75, y: 2),  // L
        0x2E: KeyPosition(x: 10.75, y: 2), // M (moved from bottom row)
        0x29: KeyPosition(x: 11.75, y: 2), // ù
        0x24: KeyPosition(x: 13, y: 2),    // Return

        // Row 3: WXCV row (y = 3) - W and Z swapped, M moved up
        0x38: KeyPosition(x: 0, y: 3),     // Left Shift
        0x0D: KeyPosition(x: 2.25, y: 3),  // W (was Z position)
        0x07: KeyPosition(x: 3.25, y: 3),  // X
        0x08: KeyPosition(x: 4.25, y: 3),  // C
        0x09: KeyPosition(x: 5.25, y: 3),  // V
        0x0B: KeyPosition(x: 6.25, y: 3),  // B
        0x2D: KeyPosition(x: 7.25, y: 3),  // N
        0x2B: KeyPosition(x: 8.25, y: 3),  // , (was M position, now ,)
        0x27: KeyPosition(x: 9.25, y: 3),  // ; (.)
        0x2F: KeyPosition(x: 10.25, y: 3), // : (/)
        0x2C: KeyPosition(x: 11.25, y: 3), // !
        0x3C: KeyPosition(x: 13, y: 3),    // Right Shift

        // Row 4: Bottom row (y = 4) - same as QWERTY
        0x3B: KeyPosition(x: 0, y: 4),     // Left Control
        0x3A: KeyPosition(x: 1.5, y: 4),   // Left Option
        0x37: KeyPosition(x: 3, y: 4),     // Left Command
        0x31: KeyPosition(x: 6.5, y: 4),   // Space
        0x36: KeyPosition(x: 10, y: 4),    // Right Command
        0x3D: KeyPosition(x: 11.5, y: 4),  // Right Option
        0x3E: KeyPosition(x: 13, y: 4),    // Right Control

        // Arrow keys
        0x7B: KeyPosition(x: 14, y: 4),    // Left Arrow
        0x7C: KeyPosition(x: 16, y: 4),    // Right Arrow
        0x7E: KeyPosition(x: 15, y: 3),    // Up Arrow
        0x7D: KeyPosition(x: 15, y: 4)     // Down Arrow
    ]

    // MARK: - QWERTZ Key Position Map

    /// QWERTZ keyboard layout positions (German layout)
    /// Main difference: Y↔Z swapped
    static let qwertzKeyPositions: [UInt16: KeyPosition] = [
        // Row 0: Number row (y = 0) - same as QWERTY
        0x35: KeyPosition(x: 0, y: 0),     // Escape
        0x12: KeyPosition(x: 1, y: 0),     // 1
        0x13: KeyPosition(x: 2, y: 0),     // 2
        0x14: KeyPosition(x: 3, y: 0),     // 3
        0x15: KeyPosition(x: 4, y: 0),     // 4
        0x17: KeyPosition(x: 5, y: 0),     // 5
        0x16: KeyPosition(x: 6, y: 0),     // 6
        0x1A: KeyPosition(x: 7, y: 0),     // 7
        0x1C: KeyPosition(x: 8, y: 0),     // 8
        0x19: KeyPosition(x: 9, y: 0),     // 9
        0x1D: KeyPosition(x: 10, y: 0),    // 0
        0x1B: KeyPosition(x: 11, y: 0),    // ß
        0x18: KeyPosition(x: 12, y: 0),    // ´
        0x33: KeyPosition(x: 13.5, y: 0),  // Delete

        // Row 1: QWERTZ row (y = 1) - Z moved here (Y position)
        0x30: KeyPosition(x: 0, y: 1),     // Tab
        0x0C: KeyPosition(x: 1.5, y: 1),   // Q
        0x0D: KeyPosition(x: 2.5, y: 1),   // W
        0x0E: KeyPosition(x: 3.5, y: 1),   // E
        0x0F: KeyPosition(x: 4.5, y: 1),   // R
        0x11: KeyPosition(x: 5.5, y: 1),   // T
        0x06: KeyPosition(x: 6.5, y: 1),   // Z (was Y position)
        0x20: KeyPosition(x: 7.5, y: 1),   // U
        0x22: KeyPosition(x: 8.5, y: 1),   // I
        0x1F: KeyPosition(x: 9.5, y: 1),   // O
        0x23: KeyPosition(x: 10.5, y: 1),  // P
        0x21: KeyPosition(x: 11.5, y: 1),  // Ü
        0x1E: KeyPosition(x: 12.5, y: 1),  // +
        0x2A: KeyPosition(x: 13.5, y: 1),  // #

        // Row 2: ASDF row (y = 2) - same structure
        0x39: KeyPosition(x: 0, y: 2),     // Caps Lock
        0x00: KeyPosition(x: 1.75, y: 2),  // A
        0x01: KeyPosition(x: 2.75, y: 2),  // S
        0x02: KeyPosition(x: 3.75, y: 2),  // D
        0x03: KeyPosition(x: 4.75, y: 2),  // F
        0x05: KeyPosition(x: 5.75, y: 2),  // G
        0x04: KeyPosition(x: 6.75, y: 2),  // H
        0x26: KeyPosition(x: 7.75, y: 2),  // J
        0x28: KeyPosition(x: 8.75, y: 2),  // K
        0x25: KeyPosition(x: 9.75, y: 2),  // L
        0x29: KeyPosition(x: 10.75, y: 2), // Ö
        0x27: KeyPosition(x: 11.75, y: 2), // Ä
        0x24: KeyPosition(x: 13, y: 2),    // Return

        // Row 3: YXCV row (y = 3) - Y moved here (Z position)
        0x38: KeyPosition(x: 0, y: 3),     // Left Shift
        0x10: KeyPosition(x: 2.25, y: 3),  // Y (was Z position)
        0x07: KeyPosition(x: 3.25, y: 3),  // X
        0x08: KeyPosition(x: 4.25, y: 3),  // C
        0x09: KeyPosition(x: 5.25, y: 3),  // V
        0x0B: KeyPosition(x: 6.25, y: 3),  // B
        0x2D: KeyPosition(x: 7.25, y: 3),  // N
        0x2E: KeyPosition(x: 8.25, y: 3),  // M
        0x2B: KeyPosition(x: 9.25, y: 3),  // ,
        0x2F: KeyPosition(x: 10.25, y: 3), // .
        0x2C: KeyPosition(x: 11.25, y: 3), // -
        0x3C: KeyPosition(x: 13, y: 3),    // Right Shift

        // Row 4: Bottom row (y = 4) - same as QWERTY
        0x3B: KeyPosition(x: 0, y: 4),     // Left Control
        0x3A: KeyPosition(x: 1.5, y: 4),   // Left Option
        0x37: KeyPosition(x: 3, y: 4),     // Left Command
        0x31: KeyPosition(x: 6.5, y: 4),   // Space
        0x36: KeyPosition(x: 10, y: 4),    // Right Command
        0x3D: KeyPosition(x: 11.5, y: 4),  // Right Option
        0x3E: KeyPosition(x: 13, y: 4),    // Right Control

        // Arrow keys
        0x7B: KeyPosition(x: 14, y: 4),    // Left Arrow
        0x7C: KeyPosition(x: 16, y: 4),    // Right Arrow
        0x7E: KeyPosition(x: 15, y: 3),    // Up Arrow
        0x7D: KeyPosition(x: 15, y: 4)     // Down Arrow
    ]

    // MARK: - Dvorak Key Position Map

    /// Dvorak keyboard layout positions
    /// Note: Since key codes are hardware-based (physical key positions), all layouts
    /// share the same physical positions. This map exists for API consistency and
    /// potential future customization. Characters shown are what the key produces in Dvorak.
    static let dvorakKeyPositions: [UInt16: KeyPosition] = [
        // Row 0: Number row (y = 0) - same physical positions as QWERTY
        0x35: KeyPosition(x: 0, y: 0),     // Escape
        0x12: KeyPosition(x: 1, y: 0),     // 1
        0x13: KeyPosition(x: 2, y: 0),     // 2
        0x14: KeyPosition(x: 3, y: 0),     // 3
        0x15: KeyPosition(x: 4, y: 0),     // 4
        0x17: KeyPosition(x: 5, y: 0),     // 5
        0x16: KeyPosition(x: 6, y: 0),     // 6
        0x1A: KeyPosition(x: 7, y: 0),     // 7
        0x1C: KeyPosition(x: 8, y: 0),     // 8
        0x19: KeyPosition(x: 9, y: 0),     // 9
        0x1D: KeyPosition(x: 10, y: 0),    // 0
        0x1B: KeyPosition(x: 11, y: 0),    // [ (produces [ in Dvorak)
        0x18: KeyPosition(x: 12, y: 0),    // ] (produces ] in Dvorak)
        0x33: KeyPosition(x: 13.5, y: 0),  // Delete

        // Row 1: Physical QWERTY row (y = 1) - produces ',.PYFGCRL/= in Dvorak
        0x30: KeyPosition(x: 0, y: 1),     // Tab
        0x0C: KeyPosition(x: 1.5, y: 1),   // Q key produces '
        0x0D: KeyPosition(x: 2.5, y: 1),   // W key produces ,
        0x0E: KeyPosition(x: 3.5, y: 1),   // E key produces .
        0x0F: KeyPosition(x: 4.5, y: 1),   // R key produces P
        0x11: KeyPosition(x: 5.5, y: 1),   // T key produces Y
        0x10: KeyPosition(x: 6.5, y: 1),   // Y key produces F
        0x20: KeyPosition(x: 7.5, y: 1),   // U key produces G
        0x22: KeyPosition(x: 8.5, y: 1),   // I key produces C
        0x1F: KeyPosition(x: 9.5, y: 1),   // O key produces R
        0x23: KeyPosition(x: 10.5, y: 1),  // P key produces L
        0x21: KeyPosition(x: 11.5, y: 1),  // [ key produces /
        0x1E: KeyPosition(x: 12.5, y: 1),  // ] key produces =
        0x2A: KeyPosition(x: 13.5, y: 1),  // \

        // Row 2: Physical ASDF row (y = 2) - produces AOEUIDHTNS- in Dvorak
        0x39: KeyPosition(x: 0, y: 2),     // Caps Lock
        0x00: KeyPosition(x: 1.75, y: 2),  // A key produces A
        0x01: KeyPosition(x: 2.75, y: 2),  // S key produces O
        0x02: KeyPosition(x: 3.75, y: 2),  // D key produces E
        0x03: KeyPosition(x: 4.75, y: 2),  // F key produces U
        0x05: KeyPosition(x: 5.75, y: 2),  // G key produces I
        0x04: KeyPosition(x: 6.75, y: 2),  // H key produces D
        0x26: KeyPosition(x: 7.75, y: 2),  // J key produces H
        0x28: KeyPosition(x: 8.75, y: 2),  // K key produces T
        0x25: KeyPosition(x: 9.75, y: 2),  // L key produces N
        0x29: KeyPosition(x: 10.75, y: 2), // ; key produces S
        0x27: KeyPosition(x: 11.75, y: 2), // ' key produces -
        0x24: KeyPosition(x: 13, y: 2),    // Return

        // Row 3: Physical ZXCV row (y = 3) - produces ;QJKXBMWVZ in Dvorak
        0x38: KeyPosition(x: 0, y: 3),     // Left Shift
        0x06: KeyPosition(x: 2.25, y: 3),  // Z key produces ;
        0x07: KeyPosition(x: 3.25, y: 3),  // X key produces Q
        0x08: KeyPosition(x: 4.25, y: 3),  // C key produces J
        0x09: KeyPosition(x: 5.25, y: 3),  // V key produces K
        0x0B: KeyPosition(x: 6.25, y: 3),  // B key produces X
        0x2D: KeyPosition(x: 7.25, y: 3),  // N key produces B
        0x2E: KeyPosition(x: 8.25, y: 3),  // M key produces M
        0x2B: KeyPosition(x: 9.25, y: 3),  // , key produces W
        0x2F: KeyPosition(x: 10.25, y: 3), // . key produces V
        0x2C: KeyPosition(x: 11.25, y: 3), // / key produces Z
        0x3C: KeyPosition(x: 13, y: 3),    // Right Shift

        // Row 4: Bottom row (y = 4) - same as QWERTY
        0x3B: KeyPosition(x: 0, y: 4),     // Left Control
        0x3A: KeyPosition(x: 1.5, y: 4),   // Left Option
        0x37: KeyPosition(x: 3, y: 4),     // Left Command
        0x31: KeyPosition(x: 6.5, y: 4),   // Space
        0x36: KeyPosition(x: 10, y: 4),    // Right Command
        0x3D: KeyPosition(x: 11.5, y: 4),  // Right Option
        0x3E: KeyPosition(x: 13, y: 4),    // Right Control

        // Arrow keys
        0x7B: KeyPosition(x: 14, y: 4),    // Left Arrow
        0x7C: KeyPosition(x: 16, y: 4),    // Right Arrow
        0x7E: KeyPosition(x: 15, y: 3),    // Up Arrow
        0x7D: KeyPosition(x: 15, y: 4)     // Down Arrow
    ]

    // MARK: - Layout Selection

    /// Get key positions for a specific keyboard layout
    /// - Parameter layout: The keyboard layout to use
    /// - Returns: Dictionary mapping key codes to positions
    static func keyPositions(for layout: Layout) -> [UInt16: KeyPosition] {
        switch layout {
        case .qwerty: return keyPositions
        case .azerty: return azertyKeyPositions
        case .qwertz: return qwertzKeyPositions
        case .dvorak: return dvorakKeyPositions
        }
    }

    // MARK: - Adjacency Threshold

    /// Distance threshold in key-widths for considering keys adjacent
    /// 1.6 captures immediate neighbors and diagonal keys
    static let adjacencyThreshold: Double = 1.6

    // MARK: - Public Methods

    /// Check if a key code is a modifier key
    /// - Parameter keyCode: The key code to check
    /// - Returns: true if the key is a modifier
    static func isModifierKey(_ keyCode: UInt16) -> Bool {
        modifierKeyCodes.contains(keyCode)
    }

    /// Filter out modifier keys from a set of key codes
    /// - Parameter keyCodes: Set of key codes to filter
    /// - Returns: Set with modifier keys removed
    static func filterModifiers(from keyCodes: Set<UInt16>) -> Set<UInt16> {
        keyCodes.subtracting(modifierKeyCodes)
    }

    // MARK: - Layout-Aware Methods

    /// Calculate the distance between two keys using a specific layout
    /// - Parameters:
    ///   - key1: First key code
    ///   - key2: Second key code
    ///   - layout: The keyboard layout to use for position lookup
    /// - Returns: Distance in key-widths, or nil if either key position is unknown
    static func distance(between key1: UInt16, and key2: UInt16, layout: Layout) -> Double? {
        let positions = keyPositions(for: layout)
        guard let pos1 = positions[key1],
              let pos2 = positions[key2] else {
            return nil
        }

        let dx = pos1.x - pos2.x
        let dy = pos1.y - pos2.y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Check if two keys are adjacent using a specific layout
    /// - Parameters:
    ///   - key1: First key code
    ///   - key2: Second key code
    ///   - layout: The keyboard layout to use for position lookup
    /// - Returns: true if keys are adjacent, false otherwise or if positions unknown
    static func areAdjacent(_ key1: UInt16, _ key2: UInt16, layout: Layout) -> Bool {
        guard let dist = distance(between: key1, and: key2, layout: layout) else {
            return false
        }
        return dist <= adjacencyThreshold
    }

    /// Get all adjacent keys for a given key using a specific layout
    /// - Parameters:
    ///   - keyCode: The key code to find neighbors for
    ///   - layout: The keyboard layout to use for position lookup
    /// - Returns: Set of adjacent key codes (excluding modifiers)
    static func adjacentKeys(for keyCode: UInt16, layout: Layout) -> Set<UInt16> {
        let positions = keyPositions(for: layout)
        guard positions[keyCode] != nil else {
            return []
        }

        var adjacent: Set<UInt16> = []
        for (otherKey, _) in positions where otherKey != keyCode {
            if areAdjacent(keyCode, otherKey, layout: layout) && !isModifierKey(otherKey) {
                adjacent.insert(otherKey)
            }
        }
        return adjacent
    }

    /// Build an adjacency graph for a set of keys using a specific layout
    /// - Parameters:
    ///   - keyCodes: Set of pressed key codes
    ///   - layout: The keyboard layout to use for position lookup
    /// - Returns: Dictionary mapping each key to its adjacent pressed keys
    static func buildAdjacencyGraph(for keyCodes: Set<UInt16>, layout: Layout) -> [UInt16: Set<UInt16>] {
        let nonModifierKeys = filterModifiers(from: keyCodes)
        var graph: [UInt16: Set<UInt16>] = [:]

        for key in nonModifierKeys {
            var neighbors: Set<UInt16> = []
            for otherKey in nonModifierKeys where otherKey != key {
                if areAdjacent(key, otherKey, layout: layout) {
                    neighbors.insert(otherKey)
                }
            }
            graph[key] = neighbors
        }

        return graph
    }
}
