# Tasks: Cat Keyboard Lock

**Input**: Design documents from `/specs/002-cat-keyboard-lock/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Required per Constitution Principle III (Test-Driven Development)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- **Source**: `CatPaws/CatPaws/` (Xcode project structure)
- **Tests**: `CatPaws/CatPawsTests/`
- **UI Tests**: `CatPaws/CatPawsUITests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project configuration and entitlements for keyboard monitoring

- [ ] T001 Add app-sandbox and Input Monitoring entitlements to CatPaws/CatPaws/CatPaws.entitlements (com.apple.security.app-sandbox, com.apple.security.device.input-monitoring)
- [ ] T002 Add NSInputMonitoringUsageDescription to CatPaws/CatPaws/Info.plist
- [ ] T003 [P] Create Services directory at CatPaws/CatPaws/Services/
- [ ] T004 [P] Create ServiceTests directory at CatPaws/CatPawsTests/ServiceTests/
- [ ] T004a [P] Configure SwiftLint in project with zero-violation policy per Constitution
- [ ] T004b [P] Configure Xcode build settings to treat warnings as errors per Constitution

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Protocols and Types

- [ ] T005 [P] Create PermissionError enum in CatPaws/CatPaws/Services/PermissionError.swift
- [ ] T006 [P] Create KeyboardMonitoring protocol in CatPaws/CatPaws/Services/KeyboardMonitoring.swift
- [ ] T007 [P] Create KeyboardMonitorDelegate protocol in CatPaws/CatPaws/Services/KeyboardMonitorDelegate.swift
- [ ] T008 [P] Create ConfigurationProviding protocol in CatPaws/CatPaws/Services/ConfigurationProviding.swift

### Shared Models

- [ ] T009 Create Configuration model with UserDefaults backing in CatPaws/CatPaws/Models/Configuration.swift

### Keyboard Monitoring (Required by ALL stories)

- [ ] T010 Create KeyboardMonitor service implementing CGEvent tap in CatPaws/CatPaws/Services/KeyboardMonitor.swift
- [ ] T011 Implement permission check/request flow in KeyboardMonitor (hasPermission, requestPermission, openPermissionSettings)
- [ ] T012 Implement CGEvent tap creation and event handling in KeyboardMonitor (startMonitoring, stopMonitoring)
- [ ] T013 Implement delegate callbacks for key down/up/modifiers in KeyboardMonitor
- [ ] T013a Implement permission denial graceful handling UI with guidance to System Settings in KeyboardMonitor (per Constitution II)

### Keyboard Adjacency Data (Required for detection)

- [ ] T014 Create KeyboardAdjacencyMap with QWERTY layout positions in CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift
- [ ] T015 Implement adjacency calculation with 1.6 threshold in KeyboardAdjacencyMap
- [ ] T016 Implement modifier key identification in KeyboardAdjacencyMap

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Cat Paw Detection (Priority: P1) 🎯 MVP

**Goal**: Detect when 3+ adjacent non-modifier keys are pressed simultaneously (cat paw pattern)

**Independent Test**: Press A, S, D, F keys simultaneously and verify detection triggers; verify modifier keys and normal typing do NOT trigger

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T017 [P] [US1] Create KeyboardStateTests in CatPaws/CatPawsTests/ModelTests/KeyboardStateTests.swift
- [ ] T018 [P] [US1] Create CatDetectionServiceTests in CatPaws/CatPawsTests/ServiceTests/CatDetectionServiceTests.swift
- [ ] T019 [P] [US1] Add test: 3+ adjacent keys triggers detection in CatDetectionServiceTests
- [ ] T020 [P] [US1] Add test: modifier-only combinations do NOT trigger in CatDetectionServiceTests
- [ ] T021 [P] [US1] Add test: sequential typing does NOT trigger in CatDetectionServiceTests
- [ ] T022 [P] [US1] Add test: formsConnectedCluster returns true for adjacent keys in CatDetectionServiceTests

### Implementation for User Story 1

- [ ] T023 [P] [US1] Create KeyboardState model in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T024 [P] [US1] Create DetectionEvent model with DetectionType enum in CatPaws/CatPaws/Models/DetectionEvent.swift
- [ ] T025 [US1] Create CatDetecting protocol in CatPaws/CatPaws/Services/CatDetecting.swift
- [ ] T026 [US1] Create CatDetectionService implementing pattern analysis in CatPaws/CatPaws/Services/CatDetectionService.swift
- [ ] T027 [US1] Implement analyzePattern method using KeyboardAdjacencyMap in CatDetectionService
- [ ] T028 [US1] Implement formsConnectedCluster using BFS/DFS in CatDetectionService
- [ ] T029 [US1] Implement modifier key filtering in CatDetectionService

**Checkpoint**: Cat paw detection works independently - can detect 3+ adjacent keys

---

## Phase 4: User Story 2 - Keyboard Lock Activation (Priority: P1)

**Goal**: Block all keyboard input when a cat pattern is detected

**Independent Test**: Trigger detection and verify keystrokes are blocked from reaching applications

### Tests for User Story 2

- [ ] T030 [P] [US2] Create LockStateTests in CatPaws/CatPawsTests/ModelTests/LockStateTests.swift
- [ ] T031 [P] [US2] Add test: state transitions (monitoring → debouncing → locked) in LockStateTests
- [ ] T032 [P] [US2] Create KeyboardLockServiceTests in CatPaws/CatPawsTests/ServiceTests/KeyboardLockServiceTests.swift
- [ ] T033 [P] [US2] Add test: shouldPassThrough returns false when locked in KeyboardLockServiceTests
- [ ] T034 [P] [US2] Add test: debounce requires 200-500ms persistence in KeyboardLockServiceTests

### Implementation for User Story 2

- [ ] T035 [P] [US2] Create LockState model with LockStatus enum in CatPaws/CatPaws/Models/LockState.swift
- [ ] T036 [US2] Create KeyboardLocking protocol in CatPaws/CatPaws/Services/KeyboardLocking.swift
- [ ] T037 [US2] Create KeyboardLockService implementing input blocking in CatPaws/CatPaws/Services/KeyboardLockService.swift
- [ ] T038 [US2] Implement shouldPassThrough returning nil for blocked events in KeyboardLockService
- [ ] T039 [US2] Create LockStateManaging protocol in CatPaws/CatPaws/Services/LockStateManaging.swift
- [ ] T040 [US2] Create LockStateManager implementing state machine in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T041 [US2] Implement debounce logic using Task.sleep in LockStateManager (use 300ms default per Configuration)
- [ ] T042 [US2] Integrate KeyboardMonitor callback with CatDetectionService and LockStateManager in KeyboardMonitor

**Checkpoint**: Keyboard locks on cat detection - input is blocked after debounce

---

## Phase 5: User Story 3 - Visual Notification (Priority: P2)

**Goal**: Show popup notification with dismiss button when keyboard locks

**Independent Test**: Trigger lock and verify popup appears with message and dismiss button; click button and verify unlock

### Tests for User Story 3

- [ ] T043 [P] [US3] Create MockNotificationPresenter for testing in CatPaws/CatPawsTests/Mocks/MockNotificationPresenter.swift
- [ ] T044 [P] [US3] Add test: show is called when entering locked state in LockStateManagerTests
- [ ] T045 [P] [US3] Add test: hide is called when exiting locked state in LockStateManagerTests
- [ ] T046 [P] [US3] Add test: dismiss callback triggers manualUnlock in LockStateManagerTests

### Implementation for User Story 3

- [ ] T047 [P] [US3] Create NotificationPresenting protocol in CatPaws/CatPaws/Services/NotificationPresenting.swift
- [ ] T048 [US3] Create CatLockPopupView SwiftUI view in CatPaws/CatPaws/Views/CatLockPopupView.swift
- [ ] T049 [US3] Create NotificationWindowController using NSPanel in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T050 [US3] Configure NSPanel with .floating level and .fullScreenAuxiliary behavior
- [ ] T051 [US3] Implement show/hide methods with dismiss callback in NotificationWindowController
- [ ] T052 [US3] Integrate NotificationPresenting with LockStateManager (show on lock, hide on unlock)
- [ ] T053 [US3] Implement cooldown state (5-10 sec) after manual unlock in LockStateManager

**Checkpoint**: Popup appears on lock with dismiss button; cooldown prevents immediate re-lock

---

## Phase 6: User Story 4 - Automatic Unlock (Priority: P1)

**Goal**: Automatically unlock keyboard when cat leaves (no keys pressed at re-check)

**Independent Test**: Trigger lock, release all keys, wait 2+ seconds, verify automatic unlock

### Tests for User Story 4

- [ ] T054 [P] [US4] Add test: performRecheck unlocks when no keys pressed in LockStateManagerTests
- [ ] T055 [P] [US4] Add test: re-check interval is configurable (default 2 sec) in LockStateManagerTests
- [ ] T056 [P] [US4] Add test: keyboard remains locked if keys still pressed at re-check in LockStateManagerTests

### Implementation for User Story 4

- [ ] T057 [US4] Implement periodic re-check timer using Task in LockStateManager
- [ ] T058 [US4] Implement performRecheck method checking KeyboardState in LockStateManager
- [ ] T059 [US4] Transition from locked to monitoring when no keys detected in LockStateManager
- [ ] T060 [US4] Ensure notification hides on automatic unlock in LockStateManager

**Checkpoint**: Keyboard auto-unlocks when cat leaves - full lock/unlock cycle works

---

## Phase 7: User Story 5 - Multi-Paw and Full Cat Detection (Priority: P2)

**Goal**: Detect cat sitting/lying (10+ keys) or multiple paw clusters

**Independent Test**: Press 10+ keys simultaneously and verify detection; verify multiple separate clusters trigger

### Tests for User Story 5

- [ ] T061 [P] [US5] Add test: 10+ keys triggers sitting detection in CatDetectionServiceTests
- [ ] T062 [P] [US5] Add test: multiple disconnected clusters triggers multiPaw detection in CatDetectionServiceTests
- [ ] T063 [P] [US5] Add test: DetectionType.sitting set for 10+ keys in CatDetectionServiceTests

### Implementation for User Story 5

- [ ] T064 [US5] Add sitting detection (10+ keys) to analyzePattern in CatDetectionService
- [ ] T065 [US5] Add multiPaw detection (multiple clusters) to analyzePattern in CatDetectionService
- [ ] T066 [US5] Update DetectionEvent creation with appropriate DetectionType in CatDetectionService
- [ ] T067 [US5] Update popup messaging based on DetectionType in CatLockPopupView

**Checkpoint**: All detection patterns work - single paw, multiple paws, and sitting cat

---

## Phase 8: Integration & App ViewModel

**Purpose**: Wire all services together through AppViewModel

- [ ] T068 Update AppViewModel to hold KeyboardMonitor instance in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T069 Update AppViewModel to hold LockStateManager instance
- [ ] T070 Update AppViewModel to hold NotificationWindowController instance
- [ ] T071 Implement service initialization and permission flow on app launch in AppViewModel
- [ ] T072 Update menu bar icon based on lock state in AppViewModel (per Constitution IV: outlined paw = unlocked, filled paw = locked, grayed paw = disabled)
- [ ] T073 Add manual unlock option to menu bar menu in CatPaws/CatPaws/MenuBar/MenuBarContentView.swift
- [ ] T074 Add Settings controls for detection configuration in CatPaws/CatPaws/Views/SettingsView.swift

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final testing, documentation, and cleanup

- [ ] T075 [P] Create integration test for full detection→lock→unlock flow in CatPaws/CatPawsTests/IntegrationTests/
- [ ] T076 [P] Add VoiceOver accessibility labels to CatLockPopupView
- [ ] T077 [P] Add sound effects for lock/unlock (optional, controlled by Configuration)
- [ ] T078 Run all tests and verify 80%+ coverage on detection logic
- [ ] T079 Run quickstart.md validation scenarios
- [ ] T080 Code cleanup and remove debug logging

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────┐
                                 ▼
Phase 2: Foundational ───────────┤
                                 │
    ┌────────────────────────────┼────────────────────────────┐
    ▼                            ▼                            ▼
Phase 3: US1        Phase 4: US2 (needs US1)    Phase 6: US4 (needs US2)
Cat Paw Detection   Keyboard Lock               Automatic Unlock
    │                            │
    │                            ▼
    │               Phase 5: US3 (needs US2)
    │               Visual Notification
    │                            │
    ▼                            ▼
Phase 7: US5 (needs US1)
Multi-Paw Detection
    │
    └────────────────────────────┬────────────────────────────┘
                                 ▼
                    Phase 8: Integration
                                 │
                                 ▼
                    Phase 9: Polish
```

### User Story Dependencies

| Story | Depends On | Can Start After |
|-------|------------|-----------------|
| US1 (Cat Paw Detection) | Foundational | Phase 2 complete |
| US2 (Keyboard Lock) | US1 | Phase 3 complete |
| US3 (Visual Notification) | US2 | Phase 4 complete |
| US4 (Automatic Unlock) | US2 | Phase 4 complete |
| US5 (Multi-Paw Detection) | US1 | Phase 3 complete |

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models before services
3. Protocols before implementations
4. Core logic before integration

### Parallel Opportunities

**Phase 2 (Foundational)**: T005, T006, T007, T008 can run in parallel (different files)

**Phase 3 (US1)**:
- Tests T017-T022 can run in parallel
- Models T023, T024 can run in parallel

**Phase 4 (US2)**:
- Tests T030-T034 can run in parallel
- Model T035 can parallel with US1 completion

**Phase 5 (US3)** and **Phase 6 (US4)**: Can run in parallel (both depend only on US2)

**Phase 7 (US5)**: Can run in parallel with Phase 4, 5, 6 (only depends on US1)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together:
Task: "Create KeyboardStateTests in CatPaws/CatPawsTests/ModelTests/KeyboardStateTests.swift"
Task: "Create CatDetectionServiceTests in CatPaws/CatPawsTests/ServiceTests/CatDetectionServiceTests.swift"
Task: "Add test: 3+ adjacent keys triggers detection"
Task: "Add test: modifier-only combinations do NOT trigger"
Task: "Add test: sequential typing does NOT trigger"
Task: "Add test: formsConnectedCluster returns true for adjacent keys"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 4)

1. Complete Phase 1: Setup (entitlements)
2. Complete Phase 2: Foundational (KeyboardMonitor, AdjacencyMap)
3. Complete Phase 3: US1 - Cat Paw Detection
4. Complete Phase 4: US2 - Keyboard Lock
5. Complete Phase 6: US4 - Automatic Unlock
6. **STOP and VALIDATE**: Test full detection→lock→unlock cycle
7. Deploy/demo - Core functionality complete!

### Full Feature (Add US3, US5)

8. Complete Phase 5: US3 - Visual Notification
9. Complete Phase 7: US5 - Multi-Paw Detection
10. Complete Phase 8: Integration
11. Complete Phase 9: Polish

### Incremental Delivery

| Increment | Stories | Value Delivered |
|-----------|---------|-----------------|
| MVP | US1 + US2 + US4 | Detects cat, blocks input, auto-unlocks |
| v1.1 | + US3 | Adds visual feedback with dismiss button |
| v1.2 | + US5 | Handles sitting/lying cat (10+ keys) |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story should be independently completable and testable
- Constitution requires tests before implementation (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
