# Tasks: Cat Detection Sensitivity Improvements

**Input**: Design documents from `/specs/008-cat-detection-sensitivity/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- Source: `CatPaws/CatPaws/`
- Tests: `CatPaws/CatPawsTests/`

---

## Phase 1: Setup

**Purpose**: No new setup required - working within existing project structure

- [ ] T001 Verify current branch is `008-cat-detection-sensitivity` and project builds cleanly

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Configuration infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: User stories cannot begin until detectionTimeWindowMs is available in Configuration

- [ ] T002 Add `detectionTimeWindowMs` property to ConfigurationProviding protocol in CatPaws/CatPaws/Services/ConfigurationProviding.swift
- [ ] T003 Implement `detectionTimeWindowMs` property in Configuration class (key, default 300, range 100-500) in CatPaws/CatPaws/Models/Configuration.swift
- [ ] T004 Add `detectionTimeWindowMs` to `resetToDefaults()` method in CatPaws/CatPaws/Models/Configuration.swift

**Checkpoint**: Configuration ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Improved Cat Paw Detection (Priority: P1) 🎯 MVP

**Goal**: Detect cat paws when 3+ adjacent keys are pressed within 300ms, even if not held simultaneously

**Independent Test**: Rapidly press 3 adjacent keys (e.g., F, G, H) within 300ms without holding them—keyboard should lock

### Implementation for User Story 1

- [ ] T005 [US1] Create `TimestampedKeyEvent` struct in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T006 [US1] Add `recentKeyPresses: [TimestampedKeyEvent]` property to KeyboardState in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T007 [US1] Add `timeWindowSeconds: TimeInterval` property to KeyboardState in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T008 [US1] Update KeyboardState initializer to accept timeWindowSeconds parameter in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T009 [US1] Add `keysInTimeWindow` computed property returning Set<UInt16> from recentKeyPresses in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T010 [US1] Add `keysForDetection` computed property returning union of pressedKeys and keysInTimeWindow (minus modifiers) in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T011 [US1] Modify `keyPressed(_:at:)` to prune old entries and add TimestampedKeyEvent in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T012 [US1] Update `clearAll()` to also clear recentKeyPresses in CatPaws/CatPaws/Models/KeyboardState.swift
- [ ] T013 [US1] Initialize KeyboardState with timeWindowSeconds from Configuration in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T014 [US1] Update `keyDidPress` delegate method to pass timestamp to keyboardState in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T015 [US1] Update `analyzeCurrentKeys()` to use `keysForDetection` instead of `nonModifierKeys` in CatPaws/CatPaws/ViewModels/AppViewModel.swift

### Unit Tests for User Story 1 (Constitution III Compliance)

- [ ] T036 [P] [US1] Add unit tests for `keysInTimeWindow` computed property (returns correct keys within window) in CatPaws/CatPawsTests/ModelTests/KeyboardStateTests.swift
- [ ] T037 [P] [US1] Add unit tests for `keysForDetection` computed property (union of pressed + windowed keys, excludes modifiers) in CatPaws/CatPawsTests/ModelTests/KeyboardStateTests.swift
- [ ] T038 [P] [US1] Add unit tests for time window pruning in `keyPressed(_:at:)` (old entries removed) in CatPaws/CatPawsTests/ModelTests/KeyboardStateTests.swift

**Checkpoint**: User Story 1 complete - rapid sequential key presses should now trigger detection

---

## Phase 4: User Story 2 - ESC Key Emergency Unlock (Priority: P2)

**Goal**: Allow users to unlock keyboard by pressing ESC 5 times consecutively within 2 seconds

**Independent Test**: Lock keyboard, press ESC 5 times quickly—keyboard should unlock

### Implementation for User Story 2

- [ ] T016 [US2] Remove `emergencyShortcutTask` property from NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T017 [US2] Remove `emergencyHoldDuration` property from NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T018 [US2] Add `escPressCount: Int` property to NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T019 [US2] Add `lastEscPressTime: Date?` property to NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T020 [US2] Add `escTimeoutSeconds` and `requiredEscPresses` constants to NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T021 [US2] Replace `handleEmergencyShortcutEvent(_:)` implementation with ESC counting logic in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T022 [US2] Remove `startEmergencyShortcutTimer()` method from NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T023 [US2] Remove `cancelEmergencyShortcutTimer()` method from NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T024 [US2] Update `stopEmergencyShortcutMonitoring()` to reset ESC counter state in CatPaws/CatPaws/Services/NotificationWindowController.swift

### Unit Tests for User Story 2 (Constitution III Compliance)

- [ ] T039 [P] [US2] Add unit tests for ESC counter increment on ESC press in CatPaws/CatPawsTests/ServiceTests/NotificationWindowControllerTests.swift
- [ ] T040 [P] [US2] Add unit tests for ESC counter reset on timeout (>2 seconds since last press) in CatPaws/CatPawsTests/ServiceTests/NotificationWindowControllerTests.swift
- [ ] T041 [P] [US2] Add unit tests for ESC counter reset on non-ESC key press in CatPaws/CatPawsTests/ServiceTests/NotificationWindowControllerTests.swift

**Checkpoint**: User Story 2 complete - ESC x5 should now unlock the keyboard

---

## Phase 5: User Story 3 - Update Lock Popup Text (Priority: P3)

**Goal**: Display "Press ESC 5 times to unlock" instead of old Cmd+Option+Escape instructions

**Independent Test**: Trigger lock, verify popup shows new ESC instructions

### Implementation for User Story 3

- [ ] T025 [US3] Update emergency shortcut hint text from "Or hold ⌘⌥⎋ for 2 seconds" to "Or press ESC 5 times to unlock" in CatPaws/CatPaws/Views/CatLockPopupView.swift
- [ ] T026 [US3] Update accessibility label for emergency unlock instructions in CatPaws/CatPaws/Views/CatLockPopupView.swift
- [ ] T027 [US3] Update Localizable.strings if emergency shortcut text is localized in CatPaws/CatPaws/Resources/Localizable.strings

**Checkpoint**: User Story 3 complete - popup shows updated instructions

---

## Phase 5b: User Story 4 - Settings UI for Time Window (Priority: P4)

**Goal**: Allow users to configure the detection time window (FR-011) in the settings UI

**Independent Test**: Open settings, adjust time window slider, verify detection sensitivity changes

### Implementation for User Story 4

- [ ] T042 [US4] Add time window slider/stepper control (100-500ms range) to settings view in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T043 [US4] Bind time window control to `configuration.detectionTimeWindowMs` in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T044 [US4] Add descriptive label explaining what the time window setting does in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T045 [US4] Update KeyboardState timeWindowSeconds when configuration changes in CatPaws/CatPaws/ViewModels/AppViewModel.swift

**Checkpoint**: User Story 4 complete - time window is user-configurable via settings

---

## Phase 6: Polish & Validation

**Purpose**: Final verification and cleanup

- [ ] T028 Run SwiftLint and fix any violations
- [ ] T029 Build and run full test suite with `xcodebuild -scheme CatPaws -configuration Debug test`
- [ ] T030 Manual test: rapid 3-key press triggers lock (US1 validation)
- [ ] T031 Manual test: normal typing does NOT trigger lock (US1 validation)
- [ ] T032 Manual test: ESC x5 unlocks keyboard (US2 validation)
- [ ] T033 Manual test: ESC x4 then wait does NOT unlock (US2 validation)
- [ ] T034 Manual test: mouse click still dismisses popup (existing behavior)
- [ ] T035 Manual test: simultaneous 3-key press still triggers (existing behavior)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies
- **Phase 2 (Foundational)**: Depends on Phase 1 - **BLOCKS all user stories**
- **Phase 3 (US1)**: Depends on Phase 2 (needs detectionTimeWindowMs)
- **Phase 4 (US2)**: Depends on Phase 2 only - **can run in parallel with US1**
- **Phase 5 (US3)**: Depends on Phase 4 (text describes US2 functionality)
- **Phase 6 (Polish)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Independent - can start after Phase 2
- **US2 (P2)**: Independent - can start after Phase 2, can run in parallel with US1
- **US3 (P3)**: Depends on US2 (describes ESC x5 functionality)

### Within User Story 1

Sequential execution required:
1. T005 → T006 → T007 → T008 (struct and properties)
2. T009 → T010 (computed properties depend on T006)
3. T011 (modifies keyPressed, uses T006)
4. T012 (modifies clearAll, uses T006)
5. T013 → T014 → T015 (AppViewModel changes depend on KeyboardState changes)

### Within User Story 2

Sequential execution required:
1. T016-T020 (property changes, can be done together as single edit)
2. T021 (new implementation depends on new properties)
3. T022-T023 (remove old methods after T021)
4. T024 (update uses new state)

### Parallel Opportunities

```text
After Phase 2 completes:
├── US1 (T005-T015) ─┬─► Phase 5 (US3)
│                    │
└── US2 (T016-T024) ─┘
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup ✓
2. Complete Phase 2: Foundational (Configuration)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test rapid key press detection
5. Deploy/demo if detection improvement is the priority

### Full Feature Delivery

1. Setup + Foundational
2. US1 (detection) + US2 (ESC unlock) in parallel
3. US3 (popup text) after US2
4. Polish & validation
5. All features complete

---

## Notes

- Unit tests added per Constitution III requirement for detection algorithms and timing logic
- CatDetectionService requires NO changes - it receives Set<UInt16>, source doesn't matter
- ESC key code is 53 (already used in existing code)
- Time window pruning happens on each key press, not via timer
- Union approach: `pressedKeys.union(keysInTimeWindow)` preserves both detection patterns
