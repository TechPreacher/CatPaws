# Tasks: CatPaws App Polish & Improvements

**Input**: Design documents from `/specs/003-app-polish-improvements/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Project structure**: `CatPaws/CatPaws/CatPaws/` (Xcode project)
- **Tests**: `CatPaws/CatPaws/CatPawsTests/`
- **UI Tests**: `CatPaws/CatPaws/CatPawsUITests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project-level tooling and configuration

- [X] T001 [P] Create .swiftlint.yml configuration file at CatPaws/CatPaws/.swiftlint.yml per research.md specifications
- [X] T002 [P] Add SwiftLint build phase script to CatPaws target in CatPaws/CatPaws.xcodeproj
- [X] T003 Configure build settings to treat warnings as errors (GCC_TREAT_WARNINGS_AS_ERRORS=YES) in CatPaws/CatPaws.xcodeproj
- [X] T004 Remove duplicate MockNotificationPresenter.swift from CatPaws/CatPaws/CatPawsTests/ (keep Mocks/ version only)

**Checkpoint**: SwiftLint integrated, build fails on warnings, test duplicates removed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 [P] Create AppStatistics model with Codable conformance in CatPaws/CatPaws/CatPaws/Models/AppStatistics.swift per data-model.md
- [X] T006 [P] Create StatisticsService for UserDefaults persistence in CatPaws/CatPaws/CatPaws/Services/StatisticsService.swift
- [X] T007 [P] Create OnboardingState model with UserDefaults persistence in CatPaws/CatPaws/CatPaws/Models/OnboardingState.swift per data-model.md
- [X] T008 [P] Create OnboardingStep enum with cases: welcome, permissionExplanation, grantPermission, testDetection, complete in CatPaws/CatPaws/CatPaws/Models/OnboardingState.swift
- [X] T009 [P] Create AppLogger utility with os.Logger subsystem "com.catpaws.app" in CatPaws/CatPaws/CatPaws/Services/AppLogger.swift per research.md
- [X] T010 Fix any existing SwiftLint violations in the codebase to achieve zero-violation baseline

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Launch at Login (Priority: P1) 🎯 MVP

**Goal**: App automatically starts when user logs into macOS

**Independent Test**: Toggle "Launch at Login" in Settings and restart Mac. Verify app starts automatically.

### Implementation for User Story 1

- [X] T011 [US1] Create LoginItemService using SMAppService.mainApp in CatPaws/CatPaws/CatPaws/Services/LoginItemService.swift per research.md
- [X] T012 [US1] Add isEnabled computed property to LoginItemService that wraps SMAppService.mainApp.status
- [X] T013 [US1] Add register() and unregister() methods to LoginItemService with error handling
- [X] T014 [US1] Add launchAtLogin property to Configuration.swift with UserDefaults persistence key "catpaws.launchAtLogin"
- [X] T015 [US1] Update GeneralSettingsView in CatPaws/CatPaws/CatPaws/Views/SettingsView.swift to bind toggle to LoginItemService
- [X] T016 [US1] Add single-instance check using NSRunningApplication in CatPaws/CatPaws/CatPaws/App/AppDelegate.swift per research.md
- [X] T017 [US1] Verify Info.plist has LSUIElement=YES for menu bar app behavior

**Checkpoint**: Launch at Login fully functional and testable

---

## Phase 4: User Story 2 - Permission Denial Handling (Priority: P1)

**Goal**: Clear guidance when Input Monitoring permission is not granted

**Independent Test**: Launch app without permission and verify guidance is clear and actionable

### Implementation for User Story 2

- [X] T018 [P] [US2] Create PermissionGuideView with permission explanation text in CatPaws/CatPaws/CatPaws/Views/PermissionGuideView.swift
- [X] T019 [US2] Add "Open System Settings" button using URL "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" per research.md
- [X] T020 [US2] Add hasInputMonitoringPermission() helper using AXIsProcessTrusted() to AppViewModel in CatPaws/CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [X] T021 [US2] Add permission status polling Timer (2-second interval) to AppViewModel when permission not granted per research.md
- [X] T022 [US2] Integrate PermissionGuideView into MenuBarContentView in CatPaws/CatPaws/CatPaws/MenuBar/MenuBarContentView.swift to show when permission not granted
- [X] T023 [US2] Handle permission revocation during operation - stop monitoring and show guide in AppViewModel

**Checkpoint**: Permission guidance fully functional and testable

---

## Phase 5: User Story 3 - First-Run Onboarding (Priority: P1)

**Goal**: Brief introduction and setup guide for new users

**Independent Test**: Delete app preferences (defaults delete) and launch CatPaws. Verify onboarding flow appears.

### Implementation for User Story 3

- [X] T024 [P] [US3] Create OnboardingViewModel to manage onboarding state and step navigation in CatPaws/CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [X] T025 [P] [US3] Create OnboardingView with multi-step flow (welcome, permission, test) in CatPaws/CatPaws/CatPaws/Views/OnboardingView.swift
- [X] T026 [US3] Add welcome step with app purpose explanation to OnboardingView
- [X] T027 [US3] Add permission explanation step that guides user to grant Input Monitoring permission
- [X] T028 [US3] Add "Test Detection" step showing users to press A+S+D+F together to verify app works
- [X] T029 [US3] Add skip functionality with "Skip" button on each onboarding step per FR-009
- [X] T030 [US3] Add onboarding window presentation logic in CatPaws/CatPaws/CatPaws/App/AppDelegate.swift - show if !hasCompletedOnboarding
- [X] T031 [US3] Persist onboarding completion flag using OnboardingState.complete() when user finishes

**Checkpoint**: Onboarding fully functional and testable

---

## Phase 6: User Story 4 - Statistics Dashboard (Priority: P2)

**Goal**: Show users how many times CatPaws has protected their keyboard

**Independent Test**: Trigger several cat detections and verify statistics update correctly

### Implementation for User Story 4

- [X] T032 [US4] Add recordBlock() call to LockStateManager when keyboard lock is triggered in CatPaws/CatPaws/CatPaws/Services/LockStateManager.swift
- [X] T033 [US4] Add daily/weekly counter reset logic based on date boundaries to StatisticsService
- [X] T034 [P] [US4] Create StatisticsView showing today/week/all-time breakdown in CatPaws/CatPaws/CatPaws/Views/StatisticsView.swift
- [X] T035 [US4] Add statistics summary ("X blocks today") to MenuBarContentView in CatPaws/CatPaws/CatPaws/MenuBar/MenuBarContentView.swift
- [X] T036 [US4] Add tappable statistics area in MenuBarContentView that shows detailed StatisticsView
- [X] T037 [US4] Add "Reset Statistics" button to Settings that calls StatisticsService.resetAll()

**Checkpoint**: Statistics dashboard fully functional and testable

---

## Phase 7: User Story 5 - Keyboard Layout Support (Priority: P2)

**Goal**: Correct cat paw detection on non-QWERTY keyboards (AZERTY, QWERTZ, Dvorak)

**Independent Test**: Switch to non-QWERTY layout and verify cat detection works correctly

### Implementation for User Story 5

- [X] T038 [P] [US5] Add Layout enum (qwerty, azerty, qwertz, dvorak) to KeyboardAdjacencyMap in CatPaws/CatPaws/CatPaws/Services/KeyboardAdjacencyMap.swift
- [X] T039 [P] [US5] Add AZERTY key position map (azertyKeyPositions) to KeyboardAdjacencyMap per data-model.md
- [X] T040 [P] [US5] Add QWERTZ key position map (qwertzKeyPositions) to KeyboardAdjacencyMap per data-model.md
- [X] T041 [P] [US5] Add Dvorak key position map (dvorakKeyPositions) to KeyboardAdjacencyMap per data-model.md
- [X] T042 [US5] Create KeyboardLayoutDetector service using TISGetInputSourceProperty in CatPaws/CatPaws/CatPaws/Services/KeyboardLayoutDetector.swift per research.md
- [X] T043 [US5] Add layout change notification observer using DistributedNotificationCenter.default() per research.md
- [X] T044 [US5] Add keyPositions(for layout:) static method to KeyboardAdjacencyMap that returns correct map for layout
- [X] T045 [US5] Integrate KeyboardLayoutDetector with CatDetectionService to use current layout's adjacency map

**Checkpoint**: Keyboard layout support fully functional and testable

---

## Phase 8: User Story 6 - Popup Multi-Monitor Support (Priority: P2)

**Goal**: Lock notification popup appears on the screen where user is actively working

**Independent Test**: Connect multiple monitors, work on secondary screen, trigger lock, verify popup appears on active screen

### Implementation for User Story 6

- [X] T046 [US6] Add activeScreen() helper method to NotificationWindowController per research.md implementation
- [X] T047 [US6] Update show() method in NotificationWindowController to use activeScreen() instead of NSScreen.main
- [X] T048 [US6] Set panel.level to .floating and panel.collectionBehavior to [.canJoinAllSpaces, .fullScreenAuxiliary] for full-screen app support

**Checkpoint**: Multi-monitor popup positioning fully functional and testable

---

## Phase 9: User Story 7 - Diagnostic Logging (Priority: P3)

**Goal**: Enable diagnostic logging for troubleshooting issues

**Independent Test**: Enable diagnostic logging, trigger various app behaviors, verify logs appear in Console.app with subsystem:com.catpaws.app

### Implementation for User Story 7

- [ ] T049 [US7] Add debugLoggingEnabled property to Configuration.swift with UserDefaults key "catpaws.debugLogging"
- [ ] T050 [US7] Add category-specific Loggers (detection, lock, permission) to AppLogger per research.md
- [ ] T051 [US7] Add conditional logging to CatDetectionService - log when pattern detected (key count only, NO key content)
- [ ] T052 [US7] Add conditional logging to LockStateManager for state transitions (lock, unlock, debounce)
- [ ] T053 [US7] Add conditional logging to KeyboardMonitor for permission status changes
- [ ] T054 [US7] Add "Enable Debug Logging" toggle to SettingsView bound to Configuration.debugLoggingEnabled
- [ ] T055 [US7] Ensure no keystroke content or PII is logged per FR-024 - audit all log calls

**Checkpoint**: Diagnostic logging fully functional and testable

---

## Phase 10: User Story 8 - Custom App Icon (Priority: P3)

**Goal**: Distinctive, professional app icon for CatPaws

**Independent Test**: Install app and verify custom icon appears in Finder, Dock, and Spotlight

### Implementation for User Story 8

- [ ] T056 [US8] Create or obtain cat paw icon design assets (16x16 through 1024x1024) - placeholder acceptable
- [ ] T057 [US8] Add icon assets to CatPaws/CatPaws/CatPaws/Assets.xcassets/AppIcon.appiconset/
- [ ] T058 [US8] Update Contents.json with all required icon sizes per FR-027

**Checkpoint**: Custom app icon visible in all required locations

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and validation

- [ ] T059 Run full SwiftLint validation and fix any remaining violations to achieve SC-008
- [ ] T060 Verify zero compiler warnings in release build to achieve SC-009
- [ ] T061 Run all tests and ensure passing (xcodebuild test)
- [ ] T062 Performance validation: verify CPU usage < 1% during idle monitoring per SC-007
- [ ] T063 Execute quickstart.md validation scenarios for all 8 user stories

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-10)**: All depend on Foundational phase completion
  - US1 (Launch at Login): No dependencies on other stories
  - US2 (Permission Handling): No dependencies on other stories
  - US3 (Onboarding): Can reference US2 permission guidance patterns, but independently testable
  - US4 (Statistics): Depends on T005-T006 (AppStatistics, StatisticsService) from Foundational
  - US5 (Keyboard Layout): No dependencies on other stories
  - US6 (Multi-Monitor): No dependencies on other stories
  - US7 (Logging): Depends on T009 (AppLogger) from Foundational
  - US8 (App Icon): No dependencies on other stories
- **Polish (Phase 11)**: Depends on all desired user stories being complete

### User Story Priority Order

1. **P1 Stories (MVP)**: US1 (Login) → US2 (Permission) → US3 (Onboarding)
2. **P2 Stories**: US4 (Statistics) → US5 (Layout) → US6 (Multi-Monitor)
3. **P3 Stories**: US7 (Logging) → US8 (Icon)

### Parallel Opportunities

- **Phase 1**: T001-T002 (SwiftLint setup tasks)
- **Phase 2**: T005-T009 (all foundational models/services)
- **US2**: T018 (PermissionGuideView) can start in parallel
- **US3**: T024-T025 (OnboardingViewModel, OnboardingView)
- **US4**: T034 (StatisticsView)
- **US5**: T038-T041 (Layout enum and all three keyboard maps)
- **Cross-story**: All P1 user stories can proceed in parallel after Foundational
- **Cross-story**: All P2 user stories can proceed in parallel after P1

---

## Parallel Example: Foundational Phase

```bash
# Launch all foundational tasks that can run in parallel:
Task: "Create AppStatistics model in Models/AppStatistics.swift"
Task: "Create StatisticsService in Services/StatisticsService.swift"
Task: "Create OnboardingState model in Models/OnboardingState.swift"
Task: "Create OnboardingStep enum in Models/OnboardingState.swift"
Task: "Create AppLogger utility in Services/AppLogger.swift"
```

## Parallel Example: User Story 5 (Keyboard Layout)

```bash
# Launch all keyboard layout map tasks together:
Task: "Add Layout enum to KeyboardAdjacencyMap.swift"
Task: "Add AZERTY key position map to KeyboardAdjacencyMap.swift"
Task: "Add QWERTZ key position map to KeyboardAdjacencyMap.swift"
Task: "Add Dvorak key position map to KeyboardAdjacencyMap.swift"
```

---

## Implementation Strategy

### MVP First (P1 Stories Only)

1. Complete Phase 1: Setup (SwiftLint, warnings-as-errors)
2. Complete Phase 2: Foundational (statistics model, onboarding state, logger)
3. Complete Phase 3-5: User Stories 1-3 (Login, Permission, Onboarding)
4. **STOP and VALIDATE**: Test each P1 story per quickstart.md
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Launch at Login) → Test independently
3. Add US2 (Permission Handling) → Test independently
4. Add US3 (Onboarding) → Test independently → **MVP Complete!**
5. Add US4 (Statistics) → Test independently
6. Add US5 (Keyboard Layout) → Test independently
7. Add US6 (Multi-Monitor) → Test independently
8. Add US7 (Logging) → Test independently
9. Add US8 (App Icon) → Test independently → **Feature Complete!**

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Existing codebase has QWERTY layout in KeyboardAdjacencyMap.swift - extend, don't replace
- Settings view already has GeneralSettingsView - add toggles to existing structure
- Reference research.md for implementation patterns (SMAppService, TIS APIs, os.Logger)
- Reference data-model.md for entity field definitions
- Reference quickstart.md for validation scenarios
