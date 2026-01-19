# Tasks: Permissions & Settings Enhancements

**Input**: Design documents from `/specs/005-permissions-settings-enhancements/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: Not explicitly requested in spec - implementation tasks only.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US5)
- Exact file paths included in all descriptions

## Path Conventions

Based on plan.md structure:
- **Source**: `CatPaws/CatPaws/` (Models/, Views/, ViewModels/, Services/, MenuBar/)
- **Tests**: `CatPaws/CatPawsTests/` (ModelTests/, ServiceTests/, ViewModelTests/)

---

## Phase 1: Setup

**Purpose**: Project initialization and shared infrastructure

- [ ] T001 Add `ApplicationServices` import capability for `AXIsProcessTrusted()` API access
- [ ] T002 [P] Create `PermissionType` enum in CatPaws/CatPaws/Models/PermissionType.swift
- [ ] T003 [P] Create `PermissionStatus` struct in CatPaws/CatPaws/Models/PermissionStatus.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Create `PermissionService.swift` with `PermissionChecking` protocol in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T005 Implement `checkAccessibility()` using `AXIsProcessTrusted()` in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T006 Implement `checkInputMonitoring()` using `CGPreflightListenEventAccess()` in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T007 Implement `getCurrentState()` returning `PermissionState` in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T008 Implement `openSettings(for:)` with URL deep links in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T009 Implement 1-second polling with `startPolling()` and `stopPolling()` in CatPaws/CatPaws/Services/PermissionService.swift
- [ ] T010 Update `OnboardingStep` enum: add `grantAccessibility` case at raw value 2, rename `grantPermission` to `grantInputMonitoring`, shift subsequent values in CatPaws/CatPaws/Models/OnboardingState.swift
- [ ] T011 Implement `OnboardingState.migrateIfNeeded()` for step value migration in CatPaws/CatPaws/Models/OnboardingState.swift
- [ ] T012 Call `OnboardingState.migrateIfNeeded()` in app initialization in CatPaws/CatPaws/App/CatPawsApp.swift

**Checkpoint**: Foundation ready - PermissionService functional, OnboardingStep enum updated with migration

---

## Phase 3: User Story 1 - Complete Onboarding with Both Permissions (Priority: P1) 🎯 MVP

**Goal**: Guide new users through granting both Accessibility and Input Monitoring permissions during onboarding

**Independent Test**: Launch app with fresh state, navigate through all onboarding steps, grant both permissions, verify app becomes fully functional

### Implementation for User Story 1

- [ ] T013 [US1] Add `hasAccessibility` published property to `OnboardingViewModel` in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T014 [US1] Update `OnboardingViewModel.init()` to check both permissions on startup in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T015 [US1] Implement Accessibility permission polling in `OnboardingViewModel` (1-second interval) in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T016 [US1] Update `nextStep()` to handle new `grantAccessibility` → `grantInputMonitoring` flow in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T017 [US1] Add `openAccessibilitySettings()` method to `OnboardingViewModel` in CatPaws/CatPaws/ViewModels/OnboardingViewModel.swift
- [ ] T018 [US1] Create Accessibility permission step view (case `.grantAccessibility`) in CatPaws/CatPaws/Views/OnboardingView.swift
- [ ] T019 [US1] Update Input Monitoring step view for renamed case `.grantInputMonitoring` in CatPaws/CatPaws/Views/OnboardingView.swift
- [ ] T020 [US1] Add "Permission Granted!" status indicator to Accessibility step UI in CatPaws/CatPaws/Views/OnboardingView.swift
- [ ] T021 [US1] Add "Continue Anyway" button to Accessibility step for non-blocking flow in CatPaws/CatPaws/Views/OnboardingView.swift

**Checkpoint**: Users can complete full onboarding with both permission steps; UI updates within 2 seconds of grant

---

## Phase 4: User Story 2 - View Permission Status in Menu Bar (Priority: P1)

**Goal**: Show individual permission status for Accessibility and Input Monitoring in menu bar dropdown

**Independent Test**: Revoke one or both permissions in System Settings, click menu bar icon, verify correct status display

### Implementation for User Story 2

- [ ] T022 [US2] Add `permissionState: PermissionState` published property to `AppViewModel` in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T023 [US2] Add `showPermissionRevokedBanner: Bool` published property to `AppViewModel` in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T024 [US2] Integrate `PermissionService` polling into `AppViewModel` for runtime monitoring in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T025 [US2] Detect permission revocation and set `showPermissionRevokedBanner = true` in CatPaws/CatPaws/ViewModels/AppViewModel.swift
- [ ] T026 [US2] Update `PermissionGuideView` to display individual status for each permission in CatPaws/CatPaws/Views/PermissionGuideView.swift
- [ ] T027 [US2] Add "Needs Permission" / "OK" status labels per permission in CatPaws/CatPaws/Views/PermissionGuideView.swift
- [ ] T028 [US2] Add individual "Open System Settings" buttons per missing permission in CatPaws/CatPaws/Views/PermissionGuideView.swift
- [ ] T029 [US2] Update `PermissionGuideView` visibility logic: show when either permission missing in CatPaws/CatPaws/Views/PermissionGuideView.swift
- [ ] T030 [US2] Add non-modal permission revocation banner to `MenuBarContentView` in CatPaws/CatPaws/MenuBar/MenuBarContentView.swift

**Checkpoint**: Menu bar shows individual permission status; revocation triggers banner notification

---

## Phase 5: User Story 3 - Menu Bar Dropdown Displays All Content (Priority: P2)

**Goal**: Ensure menu bar dropdown is tall enough to display all content without cropping

**Independent Test**: Open menu bar dropdown in various permission states, verify all text fully visible

### Implementation for User Story 3

- [ ] T031 [US3] Update `MenuBarContentView` frame to use dynamic minimum height (minHeight: 400) in CatPaws/CatPaws/MenuBar/MenuBarContentView.swift
- [ ] T032 [US3] Add `.fixedSize(horizontal: false, vertical: true)` for content-driven height in CatPaws/CatPaws/MenuBar/MenuBarContentView.swift
- [ ] T033 [US3] Add `.help()` modifier tooltips to permission status text for truncated content in CatPaws/CatPaws/Views/PermissionGuideView.swift
- [ ] T034 [US3] Add `.lineLimit()` and `.truncationMode(.tail)` with tooltip fallback in CatPaws/CatPaws/Views/PermissionGuideView.swift

**Checkpoint**: All permission text visible; truncated text shows full content on hover

---

## Phase 6: User Story 4 - Access All Settings Content (Priority: P2)

**Goal**: Ensure settings window displays all controls without cropping

**Independent Test**: Open Settings window, verify all controls visible and accessible

### Implementation for User Story 4

- [ ] T035 [US4] Update `SettingsView` frame dimensions to accommodate all content in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T036 [US4] Adjust tab content layout (General, Detection, About) to ensure full display without clipping in CatPaws/CatPaws/Views/SettingsView.swift

**Checkpoint**: All settings controls visible and functional

---

## Phase 7: User Story 5 - Reset All App Settings (Priority: P3)

**Goal**: Provide in-app reset option to restore factory defaults

**Independent Test**: Change settings, use reset, verify all return to defaults and onboarding clears

### Implementation for User Story 5

- [ ] T037 [US5] Add `resetAll()` method to `Configuration` using `removePersistentDomain()` in CatPaws/CatPaws/Models/Configuration.swift
- [ ] T038 [US5] Add `reset()` method to `OnboardingState` to clear onboarding keys in CatPaws/CatPaws/Models/OnboardingState.swift
- [ ] T039 [US5] Add "Reset All Settings" button to `GeneralSettingsView` in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T040 [US5] Add confirmation alert dialog with warning text in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T041 [US5] Implement reset action calling `Configuration.resetAll()` on confirmation in CatPaws/CatPaws/Views/SettingsView.swift
- [ ] T042 [US5] Disable/hide reset button when onboarding is in progress in CatPaws/CatPaws/Views/SettingsView.swift

**Checkpoint**: Reset clears all settings and onboarding state; disabled during onboarding

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final refinements affecting multiple user stories

- [ ] T043 [P] Update Localizable.strings with new permission step strings in CatPaws/CatPaws/Resources/Localizable.strings
- [ ] T044 [P] Add VoiceOver accessibility labels to new permission UI elements in CatPaws/CatPaws/Views/OnboardingView.swift
- [ ] T045 Code review: verify all UserDefaults keys use `catpaws.` prefix
- [ ] T046 Run quickstart.md validation checklist
- [ ] T047 Verify all acceptance scenarios from spec.md pass (including FR-019 permission revocation banner test: revoke permission while app running, verify banner appears)

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup) ─────────────────────────────────────────────────┐
                                                                  │
Phase 2 (Foundational) ◄─────────────────────────────────────────┘
    │
    ├──► Phase 3 (US1: Onboarding) 🎯 MVP
    │
    ├──► Phase 4 (US2: Menu Bar Status) - can parallel with US1
    │
    ├──► Phase 5 (US3: Dropdown Sizing) - depends on US2
    │
    ├──► Phase 6 (US4: Settings Sizing) - independent
    │
    └──► Phase 7 (US5: Reset) - independent
                                                                  │
Phase 8 (Polish) ◄────────────────────────────────────────────────┘
```

### User Story Independence

| Story | Can Start After | Dependencies |
|-------|-----------------|--------------|
| US1 (P1) | Phase 2 | None - MVP candidate |
| US2 (P1) | Phase 2 | None - can parallel with US1 |
| US3 (P2) | US2 | Builds on PermissionGuideView from US2 |
| US4 (P2) | Phase 2 | Independent |
| US5 (P3) | Phase 2 | Independent |

### Parallel Opportunities per Phase

**Phase 1**:
```text
T002 Create PermissionType enum  ─┬─► Parallel (different files)
T003 Create PermissionStatus struct ─┘
```

**Phase 2**:
```text
T005-T009 PermissionService methods ─► Sequential (same file)
T010-T011 OnboardingState changes ───► Sequential (same file)
```

**Phase 3-7**: Follow story sequence; tasks within each story are sequential (same files)

**Phase 8**:
```text
T043 Localizable.strings ──┬─► Parallel (different files)
T044 Accessibility labels ─┘
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T012)
3. Complete Phase 3: User Story 1 (T013-T021)
4. **STOP and VALIDATE**: Test onboarding flow with both permissions
5. Demo: New users can complete full permission onboarding

### Full Feature Delivery

1. MVP (above)
2. Add US2 (T022-T030): Menu bar permission status
3. Add US3 (T031-T034): Dropdown sizing
4. Add US4 (T035-T036): Settings sizing
5. Add US5 (T037-T042): Reset functionality
6. Complete Polish (T043-T047)

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 47 |
| **Phase 1 (Setup)** | 3 |
| **Phase 2 (Foundational)** | 9 |
| **User Story 1 (P1)** | 9 |
| **User Story 2 (P1)** | 9 |
| **User Story 3 (P2)** | 4 |
| **User Story 4 (P2)** | 2 |
| **User Story 5 (P3)** | 6 |
| **Phase 8 (Polish)** | 5 |
| **Parallel Opportunities** | 6 tasks marked [P] |
| **MVP Scope** | T001-T021 (21 tasks) |
