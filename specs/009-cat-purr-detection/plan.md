# Implementation Plan: Cat Purr Detection

**Branch**: `009-cat-purr-detection` | **Date**: 2026-01-21 | **Spec**: [spec.md](spec.md)  
**Input**: User request for Whisper-based cat purr detection feature

## Summary

Implement audio-based cat purr detection using the Whisper model via WhisperKit framework. The feature adds ambient audio monitoring that detects cat purring sounds and triggers keyboard lock, complementing the existing keyboard pattern detection.

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: WhisperKit (Whisper model), AVFoundation (audio capture)  
**Storage**: UserDefaults (configuration), Memory only (audio buffers)  
**Testing**: XCTest (unit), XCUITest (integration)  
**Target Platform**: macOS 14.0+  

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| Apple Platform Best Practices | ✅ | Uses native AVFoundation, follows delegate patterns |
| Privacy & Security | ✅ | On-device processing, no audio storage, clear permission request |
| Test-Driven Development | ✅ | Unit tests for services, mocks for audio/Whisper |
| User Experience | ✅ | Optional feature, clear settings, graceful degradation |
| App Store Compliance | ✅ | Proper microphone permission handling, privacy description |
| Performance | ✅ | Wake-on-sound threshold, efficient buffer processing |

## Project Structure

### Documentation

```text
specs/009-cat-purr-detection/
├── spec.md                              # Feature specification
├── plan.md                              # This implementation plan
├── tasks.md                             # Phased task list
├── data-model.md                        # Entity definitions
├── research.md                          # Technical decisions
├── quickstart.md                        # Quick implementation guide
├── checklists/
│   └── requirements.md                  # Quality checklist
└── contracts/
    ├── purr-detecting-protocol.md       # PurrDetecting protocol
    └── audio-monitoring-protocol.md     # AudioMonitoring protocol
```

### Source Code

```text
CatPaws/CatPaws/
├── Models/
│   ├── DetectionEvent.swift             # MODIFY: Add .purr case
│   ├── Configuration.swift              # MODIFY: Add purr settings
│   ├── PermissionType.swift             # MODIFY: Add .microphone
│   ├── AppStatistics.swift              # MODIFY: Add purr stats
│   ├── PurrDetectionResult.swift        # NEW: Detection result model
│   └── AudioMonitorState.swift          # NEW: Audio state model
├── Services/
│   ├── AudioMonitor.swift               # NEW: Microphone capture service
│   ├── PurrDetectionService.swift       # NEW: Whisper-based detection
│   └── PermissionService.swift          # MODIFY: Add microphone permission
├── ViewModels/
│   └── AppViewModel.swift               # MODIFY: Integrate purr detection
├── Views/
│   └── Settings/
│       └── PurrDetectionSettingsView.swift  # NEW: Purr settings UI
└── Configuration/
    ├── CatPaws.entitlements             # MODIFY: Add audio-input
    └── Info.plist                       # MODIFY: Add microphone description
```

### Tests

```text
CatPawsTests/
├── ModelTests/
│   └── PurrDetectionResultTests.swift   # NEW: Result model tests
├── ServiceTests/
│   ├── AudioMonitorTests.swift          # NEW: Audio monitor tests
│   └── PurrDetectionServiceTests.swift  # NEW: Detection service tests
├── Mocks/
│   ├── MockAudioMonitor.swift           # NEW: Audio mock
│   └── MockPurrDetectionService.swift   # NEW: Detection mock
└── IntegrationTests/
    └── PurrDetectionIntegrationTests.swift  # NEW: End-to-end tests
```

## Dependencies

### External Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| WhisperKit | Latest | On-device Whisper model inference |

**SPM Integration**:
```swift
// Package.swift or Xcode project
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
]
```

### Internal Dependencies

| Component | Depends On | Notes |
|-----------|------------|-------|
| AudioMonitor | PermissionService | Check microphone permission |
| PurrDetectionService | WhisperKit, Configuration | Model inference |
| AppViewModel | AudioMonitor, PurrDetectionService | Integration |
| PurrDetectionSettingsView | Configuration, PermissionService | Settings UI |

## Implementation Phases

### Phase 1: Foundation (Permissions & Configuration)
- Add microphone permission type and handling
- Add purr detection configuration settings
- Update entitlements and Info.plist

### Phase 2: Audio Capture (AudioMonitor)
- Implement AudioMonitor service with AVAudioEngine
- Add wake-on-sound threshold logic
- Create AudioMonitorDelegate protocol

### Phase 3: Detection (PurrDetectionService)
- Integrate WhisperKit dependency
- Implement PurrDetectionService
- Add multi-signal detection algorithm

### Phase 4: Integration (AppViewModel)
- Connect AudioMonitor to PurrDetectionService
- Integrate with LockStateManager
- Update statistics tracking

### Phase 5: UI (Settings & Status)
- Create PurrDetectionSettingsView
- Add microphone permission status indicator
- Update statistics view with purr counts

### Phase 6: Testing & Polish
- Unit tests for all new services
- Integration tests for detection flow
- Performance optimization
- Documentation

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| WhisperKit compatibility issues | High | Fallback to CoreML direct if needed |
| High battery usage | Medium | Wake-on-sound threshold, pause when inactive |
| False positives | Medium | Multi-signal detection, configurable sensitivity |
| Microphone permission denial | Low | Graceful degradation, clear messaging |

## Success Metrics

- Detection latency < 500ms
- False positive rate < 5%
- Battery impact < 5% increase during active monitoring
- Code coverage > 80% for new services
