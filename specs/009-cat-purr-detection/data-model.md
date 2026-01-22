# Data Model: Cat Purr Detection

**Feature**: 009-cat-purr-detection  
**Date**: 2026-01-21

## Entity Changes

### 1. DetectionType (MODIFIED)

**File**: `CatPaws/Models/DetectionEvent.swift`

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| `purr` | case | ADD | New detection type for audio-based purr detection |

```swift
enum DetectionType: String, Codable, CaseIterable {
    case paw          // Single paw detection (3-9 keys)
    case multiPaw     // Multiple paws (disconnected clusters)
    case sitting      // Cat sitting on keyboard (10+ keys)
    case purr         // NEW: Audio-based purr detection
}
```

---

### 2. Configuration (MODIFIED)

**File**: `CatPaws/Models/Configuration.swift`

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| `purrDetectionEnabled` | Bool | ADD | Toggle for purr detection feature |
| `purrSensitivity` | Double | ADD | Detection sensitivity (0.0-1.0) |
| `purrSoundThreshold` | Double | ADD | Wake-on-sound RMS threshold |

```swift
// New configuration keys
static let purrDetectionEnabled = "catpaws.purrDetectionEnabled"
static let purrSensitivity = "catpaws.purrSensitivity"
static let purrSoundThreshold = "catpaws.purrSoundThreshold"

// Default values
@Published var purrDetectionEnabled: Bool = false  // Opt-in
@Published var purrSensitivity: Double = 0.5       // Medium sensitivity
@Published var purrSoundThreshold: Double = 0.01   // RMS threshold
```

**Validation**:
- `purrSensitivity`: Clamped to range 0.0...1.0
- `purrSoundThreshold`: Clamped to range 0.001...0.1

---

### 3. PermissionType (MODIFIED)

**File**: `CatPaws/Models/PermissionType.swift`

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| `microphone` | case | ADD | Microphone permission for audio capture |

```swift
enum PermissionType: String, CaseIterable {
    case accessibility
    case inputMonitoring
    case microphone  // NEW
    
    var displayName: String {
        switch self {
        case .microphone: return "Microphone"
        // ... existing
        }
    }
    
    var description: String {
        switch self {
        case .microphone: return "Required to detect cat purring sounds"
        // ... existing
        }
    }
    
    var settingsURL: URL? {
        switch self {
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        // ... existing
        }
    }
}
```

---

### 4. AppStatistics (MODIFIED)

**File**: `CatPaws/Models/AppStatistics.swift`

| Field | Type | Change | Description |
|-------|------|--------|-------------|
| `totalPurrDetections` | Int | ADD | Count of purr detection events |
| `lastPurrDetection` | Date? | ADD | Timestamp of last purr detection |

```swift
@Published var totalPurrDetections: Int = 0
@Published var lastPurrDetection: Date?

// UserDefaults keys
static let totalPurrDetectionsKey = "catpaws.stats.totalPurrDetections"
static let lastPurrDetectionKey = "catpaws.stats.lastPurrDetection"
```

---

### 5. PurrDetectionResult (NEW)

**File**: `CatPaws/Models/PurrDetectionResult.swift`

| Field | Type | Description |
|-------|------|-------------|
| `confidence` | Float | Detection confidence score (0.0-1.0) |
| `detected` | Bool | Whether purr was detected above threshold |
| `timestamp` | Date | When detection occurred |
| `duration` | TimeInterval | Duration of detected purr sound |

```swift
struct PurrDetectionResult {
    let confidence: Float
    let detected: Bool
    let timestamp: Date
    let duration: TimeInterval
    
    static let none = PurrDetectionResult(
        confidence: 0,
        detected: false,
        timestamp: Date(),
        duration: 0
    )
}
```

---

### 6. AudioMonitorState (NEW)

**File**: `CatPaws/Models/AudioMonitorState.swift`

| Field | Type | Description |
|-------|------|-------------|
| `isMonitoring` | Bool | Whether audio monitoring is active |
| `currentLevel` | Float | Current audio RMS level |
| `permissionStatus` | PermissionStatus | Microphone permission state |

```swift
struct AudioMonitorState {
    var isMonitoring: Bool = false
    var currentLevel: Float = 0.0
    var permissionStatus: PermissionStatus = .notDetermined
}
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Audio Detection Flow                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │ Microphone  │
    │  Hardware   │
    └──────┬──────┘
           │ raw audio
           ▼
    ┌─────────────────┐
    │  AudioMonitor   │ ◄── Configuration.purrSoundThreshold
    │  (AVAudioEngine)│
    └──────┬──────────┘
           │ audio buffer (if level > threshold)
           ▼
    ┌─────────────────────┐
    │ PurrDetectionService│ ◄── Configuration.purrSensitivity
    │    (WhisperKit)     │
    └──────┬──────────────┘
           │ PurrDetectionResult
           ▼
    ┌─────────────────┐
    │  AppViewModel   │ ◄── Merges keyboard + purr detections
    └──────┬──────────┘
           │ DetectionEvent(type: .purr)
           ▼
    ┌─────────────────┐
    │LockStateManager │ ◄── Triggers lock on detection
    └──────┬──────────┘
           │ LockState change
           ▼
    ┌─────────────────┐
    │   Statistics    │ ◄── Updates purr detection counts
    └─────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                     Combined Detection Flow                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌─────────────────┐         ┌─────────────────┐
    │ KeyboardMonitor │         │  AudioMonitor   │
    └───────┬─────────┘         └───────┬─────────┘
            │                           │
            ▼                           ▼
    ┌─────────────────┐         ┌─────────────────────┐
    │CatDetection-    │         │PurrDetection-       │
    │Service          │         │Service              │
    └───────┬─────────┘         └───────┬─────────────┘
            │                           │
            │  DetectionEvent           │  DetectionEvent
            │  (paw/multiPaw/sitting)   │  (purr)
            │                           │
            └───────────┬───────────────┘
                        │
                        ▼
                ┌───────────────┐
                │  AppViewModel │
                │  (merges both)│
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │LockStateManager│
                └───────────────┘
```

## Configuration Defaults

| Setting | Key | Default | Range | Unit |
|---------|-----|---------|-------|------|
| Purr Detection Enabled | `catpaws.purrDetectionEnabled` | `false` | true/false | boolean |
| Purr Sensitivity | `catpaws.purrSensitivity` | `0.5` | 0.0-1.0 | ratio |
| Sound Threshold | `catpaws.purrSoundThreshold` | `0.01` | 0.001-0.1 | RMS |

## State Transitions

### AudioMonitor States

```
                    ┌───────────┐
                    │  Stopped  │ ◄── Initial state
                    └─────┬─────┘
                          │ startMonitoring() + permission granted
                          ▼
                    ┌───────────┐
           ┌───────►│Monitoring │◄────────┐
           │        └─────┬─────┘         │
           │              │               │
    resume │   pause      │ sound > threshold
           │              ▼               │
           │        ┌───────────┐         │
           └────────│Processing │─────────┘
                    └───────────┘
                          │ stopMonitoring()
                          ▼
                    ┌───────────┐
                    │  Stopped  │
                    └───────────┘
```

### Detection Event Integration

When `PurrDetectionService` detects a purr:
1. Creates `DetectionEvent(type: .purr, confidence: result.confidence)`
2. `AppViewModel` receives event via delegate
3. `LockStateManager.handleDetection(event)` triggers lock flow
4. `AppStatistics` increments `totalPurrDetections`
