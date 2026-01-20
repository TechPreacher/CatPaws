# Tasks: Persistent Keyboard Lock

**Input**: Design documents from `/specs/006-persistent-keyboard-lock/`
**Prerequisites**: plan.md, spec.md

**Tests**: No tests explicitly requested in the specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: No new project setup needed - modifying existing codebase

- [ ] T001 Review existing LockStateManager.swift implementation in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T002 [P] Review existing CatLockPopupView.swift implementation in CatPaws/CatPaws/Views/CatLockPopupView.swift
- [ ] T003 [P] Review existing Configuration.swift implementation in CatPaws/CatPaws/Models/Configuration.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core model changes that MUST be complete before user story implementation

**⚠️ CRITICAL**: These changes affect the lock state machine used by all user stories

- [ ] T004 Remove autoUnlock() method from LockState struct in CatPaws/CatPaws/Models/LockState.swift
- [ ] T005 Add hasUserExplicitlyDisabled property to Configuration in CatPaws/CatPaws/Models/Configuration.swift
- [ ] T006 Update Configuration.isEnabled setter to track explicit user changes in CatPaws/CatPaws/Models/Configuration.swift

**Checkpoint**: Foundation ready - state model updated for persistent lock behavior

---

## Phase 3: User Story 1 & 2 - Persistent Lock Until Mouse Dismiss / Remove Timer-Based Auto-Unlock (Priority: P1) 🎯 MVP

**Goal**: Keyboard lock persists indefinitely until user explicitly dismisses via mouse click - no automatic unlock based on key release or timers

**Independent Test**: Trigger a lock, press additional keys and wait several minutes - lock remains until mouse dismiss

### Implementation for User Stories 1 & 2

- [ ] T007 [US1] Remove recheckTask property and cancelRecheckTimer() calls from LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T008 [US1] Remove startRecheckTimer() method from LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T009 [US1] Remove performRecheck() method from LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T010 [US2] Remove autoUnlock() method from LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T011 [US1] Remove startRecheckTimer() call from completeDebounce() in LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T012 [US2] Remove performRecheck call from AppViewModel keyDidRelease handler in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T013 [US1] Remove recheckIntervalSec computed property from LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift

**Checkpoint**: Lock now persists until manual dismiss - no automatic unlock occurs

---

## Phase 4: User Story 1 (continued) - Emergency Keyboard Shortcut (Priority: P1)

**Goal**: Provide emergency unlock via Cmd+Option+Escape held for 2 seconds when mouse/trackpad unavailable

**Independent Test**: Trigger a lock, hold Cmd+Option+Escape for 2 seconds - lock dismisses

### Implementation for Emergency Shortcut

- [ ] T014 [US1] Add emergencyShortcutTask property to track hold duration in LockStateManager in CatPaws/CatPaws/Services/LockStateManager.swift
- [ ] T015 [US1] Add emergencyShortcutMonitor property for global event monitoring in NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T016 [US1] Implement startEmergencyShortcutMonitoring() method in NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T017 [US1] Implement stopEmergencyShortcutMonitoring() method in NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T018 [US1] Call startEmergencyShortcutMonitoring() in show() method of NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T019 [US1] Call stopEmergencyShortcutMonitoring() in hide() method of NotificationWindowController in CatPaws/CatPaws/Services/NotificationWindowController.swift
- [ ] T020 [US1] Add emergency shortcut hint text to CatLockPopupView in CatPaws/CatPaws/Views/CatLockPopupView.swift
- [ ] T021 [US1] Add accessibility label for emergency shortcut hint in CatLockPopupView in CatPaws/CatPaws/Views/CatLockPopupView.swift

**Checkpoint**: User Story 1 complete - persistent lock with mouse dismiss and emergency shortcut

---

## Phase 5: User Story 3 - Auto-Enable on App Start (Priority: P2)

**Goal**: CatPaws monitoring automatically enabled when app launches (unless user explicitly disabled it)

**Independent Test**: Launch CatPaws fresh - monitoring is active without user interaction

### Implementation for User Story 3

- [ ] T022 [US3] Add shouldAutoEnable computed property to Configuration in CatPaws/CatPaws/Models/Configuration.swift
- [ ] T023 [US3] Update AppViewModel init to check shouldAutoEnable and start monitoring in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T024 [US3] Add autoStartMonitoringIfNeeded() method to AppViewModel in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T025 [US3] Call autoStartMonitoringIfNeeded() after permission check in AppViewModel init in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T026 [US3] Update toggleActive() to set hasUserExplicitlyDisabled when user disables in CatPaws/CatPaws/ViewModels/AppViewModel.swift

**Checkpoint**: User Story 3 complete - app auto-enables on startup

---

## Phase 6: User Story 4 - Auto-Enable After Onboarding Completion (Priority: P2)

**Goal**: Monitoring automatically enabled when user completes or skips onboarding

**Independent Test**: Complete onboarding flow - monitoring is immediately active

### Implementation for User Story 4

- [ ] T027 [US4] Update OnboardingViewModel completeOnboarding() to enable monitoring in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T028 [US4] Update OnboardingViewModel skip() to enable monitoring in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T029 [US4] Add enableMonitoringAfterOnboarding() callback to OnboardingViewModel in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T030 [US4] Wire onComplete callback in AppDelegate to trigger monitoring enable in CatPaws/CatPaws/App/AppDelegate.swift
- [ ] T031 [US4] Ensure Configuration.isEnabled is set to true on onboarding completion in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift

**Checkpoint**: User Story 4 complete - monitoring auto-enabled after onboarding

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup and validation

- [ ] T032 [P] Remove unused recheckIntervalSec from ConfigurationProviding protocol in CatPaws/CatPaws/Services/ConfigurationProviding.swift
- [ ] T033 [P] Remove recheckIntervalSec property from Configuration in CatPaws/CatPaws/Models/Configuration.swift
- [ ] T034 [P] Update any tests that reference removed auto-unlock behavior in CatPawsTests/
- [ ] T040 [P] Handle edge case: dismiss lock and unlock keyboard when user disables monitoring while locked in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T035 [P] Verify lock popup displays correctly with emergency shortcut hint
- [ ] T036 Build and test complete flow: detection → lock → mouse dismiss
- [ ] T037 Build and test complete flow: detection → lock → emergency shortcut dismiss
- [ ] T038 Build and test auto-enable on fresh app launch
- [ ] T039 Build and test auto-enable after onboarding completion

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - review existing code
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all user stories
- **User Stories 1 & 2 (Phase 3)**: Depends on Phase 2 - core lock behavior
- **User Story 1 continued (Phase 4)**: Depends on Phase 3 - emergency shortcut
- **User Story 3 (Phase 5)**: Depends on Phase 2 - can parallel with Phase 3/4
- **User Story 4 (Phase 6)**: Depends on Phase 5 - uses auto-enable logic
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **User Stories 1 & 2 (P1)**: Core behavior change - must complete first for MVP
- **User Story 3 (P2)**: Can start after Foundational - auto-enable on startup
- **User Story 4 (P2)**: Depends on User Story 3's Configuration changes

### Parallel Opportunities

Within Phase 1:
- T002 and T003 can run in parallel with T001

Within Phase 2:
- T005 and T006 modify same file - sequential

Within Phase 3:
- T007-T013 are sequential (same file modifications)

Within Phase 4:
- T015-T019 are sequential (NotificationWindowController)
- T020-T021 can run parallel with T015-T019 (different file)

Within Phase 5:
- All sequential (related logic)

Within Phase 7:
- T032, T033, T034, T035 can run in parallel

---

## Parallel Example: Phase 4

```text
# These can run in parallel (different files):
Batch 1:
- T014 (LockStateManager - property)
- T020 (CatLockPopupView - UI)
- T021 (CatLockPopupView - accessibility)

# Then sequential within NotificationWindowController:
Batch 2:
- T015 → T016 → T017 → T018 → T019
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (review)
2. Complete Phase 2: Foundational (model changes)
3. Complete Phase 3: Remove auto-unlock
4. Complete Phase 4: Add emergency shortcut
5. **STOP and VALIDATE**: Test lock persistence and dismiss methods
6. Deploy/demo if ready

### Full Feature Delivery

1. Complete MVP (Phases 1-4)
2. Add Phase 5: Auto-enable on startup
3. Add Phase 6: Auto-enable after onboarding
4. Complete Phase 7: Polish and validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- User Stories 1 & 2 are combined in Phase 3 as they're both P1 and tightly coupled
- Emergency shortcut implementation spans LockStateManager, NotificationWindowController, and CatLockPopupView
- Configuration.hasUserExplicitlyDisabled is key for distinguishing auto-enable scenarios
- Commit after each phase for easier rollback if needed
