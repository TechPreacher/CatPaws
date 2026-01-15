# Tasks: Swift Project Structure Initialization

**Input**: Design documents from `/specs/001-swift-project-structure/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: No explicit test implementation requested in specification. Project structure includes test target scaffolding but actual test code is deferred to feature implementation phases.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md, this is a macOS menu bar application:

```
CatPaws/
├── CatPaws.xcodeproj/
├── CatPaws/           # Main app target
├── CatPawsTests/      # Unit test target
└── CatPawsUITests/    # UI test target
```

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create Xcode project and basic structure

- [x] T001 Create CatPaws.xcodeproj with macOS app target, deployment target macOS 14.0, Swift 5.9
- [x] T002 Configure project as menu bar app (LSUIElement=true) in CatPaws/Configuration/Info.plist
- [x] T003 [P] Configure SwiftLint with project-specific rules in .swiftlint.yml
- [x] T004 [P] Create entitlements file with sandbox and input-monitoring in CatPaws/Configuration/CatPaws.entitlements
- [x] T005 [P] Add unit test target CatPawsTests to CatPaws.xcodeproj
- [x] T006 [P] Add UI test target CatPawsUITests to CatPaws.xcodeproj

---

## Phase 2: Foundational (Folder Structure)

**Purpose**: Create all folder groups and placeholder files that MUST exist before any feature code

**⚠️ CRITICAL**: Complete this phase before any user story implementation

- [x] T007 [P] Create CatPaws/App/ group in Xcode project
- [x] T008 [P] Create CatPaws/MenuBar/ group in Xcode project
- [x] T009 [P] Create CatPaws/Views/ group in Xcode project
- [x] T010 [P] Create CatPaws/ViewModels/ group in Xcode project
- [x] T011 [P] Create CatPaws/Models/ group in Xcode project
- [x] T012 [P] Create CatPaws/Services/ group with .gitkeep placeholder
- [x] T013 [P] Create CatPaws/Utilities/ group with .gitkeep placeholder
- [x] T014 [P] Create CatPaws/Resources/ group in Xcode project
- [x] T015 [P] Create CatPaws/Configuration/ group in Xcode project
- [x] T016 [P] Create CatPawsTests/ViewModelTests/ group with .gitkeep placeholder
- [x] T017 [P] Create CatPawsTests/ModelTests/ group with .gitkeep placeholder
- [x] T018 [P] Create CatPawsTests/ServiceTests/ group with .gitkeep placeholder
- [x] T019 [P] Create CatPawsUITests/MenuBarTests/ group with .gitkeep placeholder

**Checkpoint**: All folder groups exist and project compiles (empty)

---

## Phase 3: User Story 1 - Developer Opens New Project (Priority: P1) 🎯 MVP

**Goal**: Developer can clone repo, open project in Xcode, see organized structure, build successfully

**Independent Test**: Open CatPaws.xcodeproj in Xcode, verify folder groups display correctly, build succeeds with zero errors/warnings

### Implementation for User Story 1

- [x] T020 [P] [US1] Create CatPawsApp.swift with @main entry point in CatPaws/App/CatPawsApp.swift
- [x] T021 [P] [US1] Create AppDelegate.swift with NSApplicationDelegateAdaptor setup in CatPaws/App/AppDelegate.swift
- [x] T022 [P] [US1] Create StatusItemManager.swift skeleton in CatPaws/MenuBar/StatusItemManager.swift
- [x] T023 [P] [US1] Create MenuBarView.swift skeleton in CatPaws/MenuBar/MenuBarView.swift
- [x] T024 [P] [US1] Create PopoverView.swift skeleton in CatPaws/Views/PopoverView.swift
- [x] T025 [P] [US1] Create SettingsView.swift skeleton in CatPaws/Views/SettingsView.swift
- [x] T026 [P] [US1] Create AppViewModel.swift skeleton in CatPaws/ViewModels/AppViewModel.swift
- [x] T027 [P] [US1] Create AppState.swift skeleton in CatPaws/Models/AppState.swift
- [x] T028 [US1] Wire AppDelegate to StatusItemManager for menu bar initialization in CatPaws/App/AppDelegate.swift
- [x] T029 [US1] Verify project builds with zero errors and zero warnings

**Checkpoint**: Project opens in Xcode, structure is visible, builds successfully

---

## Phase 4: User Story 2 - Developer Adds New Feature Code (Priority: P2)

**Goal**: Developer can easily identify where to add new views, models, services, utilities

**Independent Test**: Inspect folder structure, each architectural component has obvious designated location

### Implementation for User Story 2

- [x] T030 [P] [US2] Create Assets.xcassets with AppIcon placeholder in CatPaws/Resources/Assets.xcassets
- [x] T031 [P] [US2] Add MenuBarIcon image set (template, outlined) in CatPaws/Resources/Assets.xcassets/MenuBarIcon.imageset
- [x] T032 [P] [US2] Add MenuBarIconActive image set (template, filled) in CatPaws/Resources/Assets.xcassets/MenuBarIconActive.imageset
- [x] T033 [P] [US2] Add MenuBarIconDisabled image set (template, grayed) in CatPaws/Resources/Assets.xcassets/MenuBarIconDisabled.imageset
- [x] T034 [P] [US2] Add AccentColor color set in CatPaws/Resources/Assets.xcassets/AccentColor.colorset
- [x] T035 [P] [US2] Create Localizable.strings placeholder in CatPaws/Resources/Localizable.strings
- [x] T036 [US2] Verify all placeholder groups are visible in Xcode navigator

**Checkpoint**: All architectural folders visible, assets catalog ready, developer can add code to appropriate locations

---

## Phase 5: User Story 3 - Developer Runs Tests (Priority: P3)

**Goal**: Developer can run test suite, test structure mirrors app structure

**Independent Test**: Run tests via Cmd+U in Xcode, tests execute (even if empty), structure matches app

### Implementation for User Story 3

- [ ] T037 [P] [US3] Create placeholder test file in CatPawsTests/ViewModelTests/AppViewModelTests.swift
- [ ] T038 [P] [US3] Create placeholder test file in CatPawsTests/ModelTests/AppStateTests.swift
- [ ] T039 [P] [US3] Create placeholder test file in CatPawsTests/ServiceTests/.gitkeep (empty, ready for services)
- [ ] T040 [P] [US3] Create placeholder UI test file in CatPawsUITests/MenuBarTests/MenuBarUITests.swift
- [ ] T041 [US3] Configure CatPawsTests target to host CatPaws app in Xcode project settings
- [ ] T042 [US3] Configure CatPawsUITests target to host CatPaws app in Xcode project settings
- [ ] T043 [US3] Verify test suite runs successfully via xcodebuild test command

**Checkpoint**: All test targets configured, tests run (pass trivially), structure mirrors app

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [ ] T044 Verify Info.plist contains all required keys (LSUIElement, bundle ID, version) in CatPaws/Configuration/Info.plist
- [ ] T045 Verify entitlements contain sandbox and input-monitoring in CatPaws/Configuration/CatPaws.entitlements
- [ ] T046 Run SwiftLint and confirm zero violations
- [ ] T047 Run full build and test suite, confirm zero errors and zero warnings
- [ ] T048 Validate against quickstart.md instructions (clone, open, build, run tests)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - No dependencies on US1
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - No dependencies on US1/US2

### Within Each User Story

- Files marked [P] can be created in parallel
- Wire-up tasks (T028, T041, T042) depend on skeleton files existing
- Verification tasks depend on all implementation tasks

### Parallel Opportunities

**Phase 1 (Setup)**: T003-T006 can run in parallel after T001, T002
**Phase 2 (Foundational)**: All T007-T019 can run in parallel
**Phase 3 (US1)**: T020-T027 can run in parallel, then T028, then T029
**Phase 4 (US2)**: T030-T035 can run in parallel, then T036
**Phase 5 (US3)**: T037-T040 can run in parallel, then T041-T043

---

## Parallel Example: User Story 1

```bash
# Launch all skeleton files for User Story 1 together:
Task: "Create CatPawsApp.swift in CatPaws/App/CatPawsApp.swift"
Task: "Create AppDelegate.swift in CatPaws/App/AppDelegate.swift"
Task: "Create StatusItemManager.swift in CatPaws/MenuBar/StatusItemManager.swift"
Task: "Create MenuBarView.swift in CatPaws/MenuBar/MenuBarView.swift"
Task: "Create PopoverView.swift in CatPaws/Views/PopoverView.swift"
Task: "Create SettingsView.swift in CatPaws/Views/SettingsView.swift"
Task: "Create AppViewModel.swift in CatPaws/ViewModels/AppViewModel.swift"
Task: "Create AppState.swift in CatPaws/Models/AppState.swift"

# Then sequentially:
Task: "Wire AppDelegate to StatusItemManager"
Task: "Verify build succeeds"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T019)
3. Complete Phase 3: User Story 1 (T020-T029)
4. **STOP and VALIDATE**: Open in Xcode, verify structure, build successfully
5. This is the minimum viable deliverable

### Incremental Delivery

1. Setup + Foundational → Project exists, compiles empty
2. Add User Story 1 → Project has code structure, builds successfully (MVP!)
3. Add User Story 2 → Assets and resources in place, ready for feature code
4. Add User Story 3 → Test infrastructure ready, team can write tests
5. Polish → Final validation, all success criteria met

### Single Developer Strategy

Execute phases sequentially: Setup → Foundational → US1 → US2 → US3 → Polish

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Commit after each phase completion
- Stop at any checkpoint to validate progress
- All paths are relative to repository root (CatPaws/)
