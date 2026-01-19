# Tasks: Onboarding UI Fixes

**Input**: Design documents from `/specs/004-onboarding-ui-fixes/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Tests**: Existing UI tests will be updated. No new test files needed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **macOS App**: `CatPaws/CatPaws/` contains main app code
- **UI Tests**: `CatPaws/CatPawsUITests/` contains UI test code

---

## Phase 1: Setup

**Purpose**: No setup tasks required - this feature modifies existing files only.

**Checkpoint**: Proceed directly to user story implementation.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Window height fix affects all onboarding steps and must be completed first.

**⚠️ CRITICAL**: Window height must be updated before testing any UI fixes.

- [X] T001 Update onboarding window height from 400pt to 500pt in CatPaws/CatPaws/App/AppDelegate.swift (NSWindow contentRect)
- [X] T002 Update onboarding view frame height from 400pt to 500pt in CatPaws/CatPaws/Views/OnboardingView.swift (.frame modifier on line 31)

**Checkpoint**: Foundation ready - window can now display all content without clipping.

---

## Phase 3: User Story 1 - Complete Onboarding Flow Without UI Issues (Priority: P1) 🎯 MVP

**Goal**: Ensure all onboarding content is fully visible with the new S-E-D key pattern.

**Independent Test**: Launch app with fresh state, navigate through all steps, verify text is visible and keys display in triangular pattern.

### Implementation for User Story 1

- [X] T003 [US1] Add .fixedSize(horizontal: false, vertical: true) modifier to instruction text in TestDetectionStepView in CatPaws/CatPaws/Views/OnboardingView.swift (around line 307-310)
- [X] T004 [US1] Replace ASDF HStack with S-E-D triangular layout using VStack+HStack in TestDetectionStepView in CatPaws/CatPaws/Views/OnboardingView.swift (lines 312-317)
- [X] T005 [US1] Update instruction text from "four keys" to "three keys" in TestDetectionStepView in CatPaws/CatPaws/Views/OnboardingView.swift (line 307)
- [X] T006 [US1] Update UI test assertions for new key pattern (S-E-D instead of ASDF) in CatPaws/CatPawsUITests/OnboardingTests/OnboardingUITests.swift (No changes needed - tests don't check specific keys)

**Checkpoint**: At this point, User Story 1 should be fully functional - all onboarding text visible, triangular key pattern displayed.

---

## Phase 4: User Story 2 - Grant Accessibility Permission Successfully (Priority: P1)

**Goal**: Ensure CatPaws appears in Input Monitoring list when user clicks "Open System Settings".

**Independent Test**: Click "Open System Settings" on step 3 and verify CatPaws is listed in Input Monitoring.

### Implementation for User Story 2

- [X] T007 [US2] Verify event tap is created on app launch to trigger Input Monitoring registration in CatPaws/CatPaws/Services/KeyboardMonitorService.swift
- [X] T008 [US2] If needed, add early event tap creation attempt during app initialization in CatPaws/CatPaws/App/AppDelegate.swift or CatPaws/CatPaws/ViewModels/AppViewModel.swift

**Checkpoint**: At this point, User Story 2 should be functional - CatPaws appears in Input Monitoring list.

---

## Phase 5: User Story 3 - Exit App When Permission Not Granted (Priority: P2)

**Goal**: Add visible "Quit" option to the permission-required menu bar dropdown.

**Independent Test**: Launch app without permission, click menu bar icon, verify "Quit CatPaws" button is visible and functional.

### Implementation for User Story 3

- [X] T009 [US3] Add "Quit CatPaws" button below "Open System Settings" button in CatPaws/CatPaws/Views/PermissionGuideView.swift (after line 51)
- [X] T010 [US3] Style the Quit button consistently with existing link-style buttons using .buttonStyle(.link)
- [X] T011 [US3] Implement quit action using NSApplication.shared.terminate(nil) in the button action

**Checkpoint**: At this point, User Story 3 should be functional - users can quit from permission-required state.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [X] T012 Run full UI test suite to verify all onboarding tests pass: xcodebuild test -scheme CatPaws -destination 'platform=macOS'
- [ ] T013 Manual verification: Reset defaults and test complete onboarding flow with fresh state
- [X] T014 Verify SwiftLint passes with zero violations

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: Must complete first - window height affects all stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion
- **User Story 2 (Phase 4)**: Depends on Phase 2 completion, can run parallel to US1
- **User Story 3 (Phase 5)**: Depends on Phase 2 completion, can run parallel to US1/US2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Phase 2 - Independent of other stories
- **User Story 3 (P2)**: Can start after Phase 2 - Independent of other stories

### Within Each User Story

- UI changes before test updates
- Complete story before moving to next priority

### Parallel Opportunities

- T001 and T002 modify different files but are related (same constant) - execute sequentially
- T003, T004, T005 modify same file - execute sequentially
- User Stories 1, 2, 3 can technically run in parallel after Phase 2 (different files)

---

## Parallel Example: After Phase 2

```bash
# These user stories modify different files and can run in parallel:
# US1: OnboardingView.swift changes (T003-T006)
# US2: KeyboardMonitorService/AppDelegate verification (T007-T008)
# US3: PermissionGuideView.swift changes (T009-T011)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (window height)
2. Complete Phase 3: User Story 1 (text overflow, key pattern)
3. **STOP and VALIDATE**: Test onboarding flow visually
4. Proceed to remaining stories

### Incremental Delivery

1. Phase 2 → Window height fixed
2. Add User Story 1 → Text visible, S-E-D pattern displayed
3. Add User Story 2 → Permission registration verified
4. Add User Story 3 → Quit button added
5. Phase 6 → Full test suite passes

---

## Notes

- All tasks modify existing files - no new file creation needed
- Window height change (Phase 2) is the foundation for all other fixes
- The S-E-D key pattern change requires updating both the view layout AND instruction text
- Quit button in PermissionGuideView provides redundant exit path (Cmd+Q still works)
- Verify tests after each user story to catch regressions early
