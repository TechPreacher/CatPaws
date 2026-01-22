# Tasks: Cat Purr Detection

**Input**: Design documents from `/specs/009-cat-purr-detection/`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel with other [P] tasks in same phase
- **[Story]**: Which user story (US1, US2, US3, or INFRA for infrastructure)

---

## Phase 1: Foundation - Permissions & Configuration

- [x] T001 [INFRA] Add `com.apple.security.device.audio-input` entitlement to `CatPaws.entitlements`
- [x] T002 [INFRA] Add `NSMicrophoneUsageDescription` to `Info.plist` with appropriate message
- [x] T003 [P] [INFRA] Add `.microphone` case to `PermissionType` enum with settingsURL and descriptions
- [x] T004 [P] [INFRA] Extend `PermissionService` with microphone permission checking using `AVCaptureDevice`
- [x] T005 [P] [INFRA] Add purr detection settings to `Configuration.swift` (enabled, sensitivity, threshold)
- [x] T006 [INFRA] Write unit tests for microphone permission checking

**Phase 1 Exit Criteria**: Microphone permission can be checked and requested; purr settings persist.

---

## Phase 2: Audio Capture - AudioMonitor Service

- [x] T007 [US1] Create `AudioMonitoring` protocol in `contracts/audio-monitoring-protocol.md`
- [x] T008 [US1] Create `AudioMonitorDelegate` protocol for buffer callbacks
- [x] T009 [US1] Implement `AudioMonitor` service with AVAudioEngine
- [x] T010 [US1] Add wake-on-sound threshold logic (RMS level calculation)
- [x] T011 [US1] Add start/stop/pause monitoring methods
- [x] T012 [P] [INFRA] Create `AudioMonitorState` model
- [x] T013 [US1] Write unit tests for AudioMonitor with mock audio engine

**Phase 2 Exit Criteria**: AudioMonitor captures microphone input and forwards buffers above threshold.

---

## Phase 3: Detection - PurrDetectionService

- [~] T014 [INFRA] Add WhisperKit SPM dependency to Xcode project (see whisperkit-integration.md)
- [x] T015 [US1] Create `PurrDetecting` protocol in `contracts/purr-detecting-protocol.md`
- [x] T016 [US1] Create `PurrDetectionResult` model
- [x] T017 [US1] Implement `PurrDetectionService` with WhisperKit integration
- [x] T018 [US1] Implement multi-signal detection algorithm (keywords + frequency analysis)
- [x] T019 [US2] Add sensitivity-based threshold adjustment
- [x] T020 [US1] Write unit tests for PurrDetectionService with mock WhisperKit

**Phase 3 Exit Criteria**: PurrDetectionService analyzes audio and returns detection results.

---

## Phase 4: Integration - AppViewModel & Lock Flow

- [x] T021 [US1] Add `.purr` case to `DetectionType` enum
- [x] T022 [US1] Create `DetectionEvent` factory method for purr events
- [x] T023 [US1] Integrate `AudioMonitor` into `AppViewModel`
- [x] T024 [US1] Integrate `PurrDetectionService` into `AppViewModel`
- [x] T025 [US1] Connect purr detection to `LockStateManager` flow
- [x] T026 [US1] Handle audio monitoring lifecycle (app active/inactive, system sleep)
- [ ] T027 [US1] Write integration tests for purr → lock flow

**Phase 4 Exit Criteria**: Purr detection triggers keyboard lock through existing lock flow.

---

## Phase 5: Statistics - Tracking & Persistence

- [x] T028 [US3] Add `totalPurrDetections` and `lastPurrDetection` to `AppStatistics`
- [x] T029 [US3] Update statistics on purr detection events
- [x] T030 [US3] Add UserDefaults persistence for purr statistics
- [x] T031 [US3] Write unit tests for purr statistics

**Phase 5 Exit Criteria**: Purr detection events are counted and persisted in statistics.

---

## Phase 6: UI - Settings & Status Display

- [x] T032 [US1] Create `PurrDetectionSettingsView` with enable toggle
- [x] T033 [US1] Add microphone permission status indicator with "Open Settings" button
- [x] T034 [US2] Add sensitivity slider to settings view
- [x] T035 [US3] Update statistics view to display purr detection counts
- [x] T036 [P] [INFRA] Add purr detection section to main settings navigation
- [ ] T037 [US1] Write UI tests for purr detection settings

**Phase 6 Exit Criteria**: Users can enable/configure purr detection and view statistics.

---

## Phase 7: Polish & Documentation

- [x] T038 [INFRA] Performance optimization - profile and optimize audio processing
- [x] T039 [INFRA] Memory leak testing for extended monitoring sessions
- [x] T040 [INFRA] Add logging for purr detection debugging
- [x] T041 [INFRA] Update README with purr detection feature documentation
- [x] T042 [INFRA] Code review and cleanup
- [ ] T043 [INFRA] Run full test suite and verify >80% coverage

**Phase 7 Exit Criteria**: Feature is polished, documented, and ready for release.

---

## Dependencies & Execution Order

```
Phase 1 (Foundation)
    │
    ├── T001 ──► T002 (sequential - entitlements)
    │
    ├── T003 ─┬─► T006 (permission type → tests)
    ├── T004 ─┤
    └── T005 ─┘
    
Phase 2 (Audio)
    │
    T007 ──► T008 ──► T009 ──► T010 ──► T011 ──► T013
                              │
                              └── T012 (parallel)

Phase 3 (Detection)
    │
    T014 ──► T015 ──► T016 ──► T017 ──► T018 ──► T019 ──► T020

Phase 4 (Integration)
    │
    T021 ──► T022 ──► T023 ──► T024 ──► T025 ──► T026 ──► T027

Phase 5 (Statistics)
    │
    T028 ──► T029 ──► T030 ──► T031

Phase 6 (UI)
    │
    T032 ──► T033 ──► T034 ──► T035
                              │
                              └── T036 (parallel) ──► T037

Phase 7 (Polish)
    │
    T038 ─┬─► T042 ──► T043
    T039 ─┤
    T040 ─┤
    T041 ─┘
```

## Parallel Execution Opportunities

| Phase | Parallel Tasks | Notes |
|-------|----------------|-------|
| 1 | T003, T004, T005 | Independent model/service changes |
| 2 | T012 with T010-T011 | Model can be created alongside service |
| 6 | T036 with T034-T035 | Navigation update independent of content |
| 7 | T038-T041 | All polish tasks independent |

## Estimated Effort

| Phase | Tasks | Estimate |
|-------|-------|----------|
| Phase 1 | 6 | 2-3 hours |
| Phase 2 | 7 | 4-5 hours |
| Phase 3 | 7 | 6-8 hours |
| Phase 4 | 7 | 4-5 hours |
| Phase 5 | 4 | 2-3 hours |
| Phase 6 | 6 | 3-4 hours |
| Phase 7 | 6 | 3-4 hours |
| **Total** | **43** | **24-32 hours** |
