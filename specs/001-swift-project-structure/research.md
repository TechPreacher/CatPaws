# Research: Swift Project Structure Initialization

**Feature**: 001-swift-project-structure
**Date**: 2026-01-15

## Research Tasks

### 1. macOS Menu Bar App Project Structure Best Practices

**Decision**: Use a hybrid SwiftUI + AppKit approach with MVVM architecture

**Rationale**:
- SwiftUI alone cannot create menu bar apps directly; AppKit's `NSStatusItem` is required
- SwiftUI can be used for popover content and settings views
- MVVM provides clear separation for testability (per constitution requirement)
- Apple's modern app templates follow this pattern for menu bar utilities

**Alternatives Considered**:
- Pure AppKit: Rejected - more verbose, less modern, harder to maintain
- Pure SwiftUI with MenuBarExtra: Limited customization, less control over behavior
- MVC pattern: Rejected - harder to test, less separation of concerns

### 2. Xcode Project Organization for Menu Bar Apps

**Decision**: Single xcodeproj with app target + two test targets (unit + UI)

**Rationale**:
- Menu bar apps are single-purpose utilities; monorepo complexity not needed
- Separate UI test target allows testing menu bar interactions
- Unit test target for model/viewmodel/service logic
- Matches Apple's default project template structure

**Alternatives Considered**:
- Swift Package Manager workspace: Rejected - overkill for single app, adds complexity
- Single test target: Rejected - UI tests have different execution requirements

### 3. Folder Organization Within App Target

**Decision**: Feature-agnostic flat structure with architectural folders

**Rationale**:
- Menu bar apps are typically small; feature-based folders add unnecessary nesting
- Architectural folders (Models, Views, ViewModels, Services) match MVVM pattern
- Separate MenuBar folder for platform-specific code keeps SwiftUI views portable
- Configuration folder isolates build-related files

**Alternatives Considered**:
- Feature-based folders: Rejected - premature for initial structure, can refactor later
- Single Sources folder: Rejected - doesn't guide developers on where to place code

### 4. SwiftUI App Lifecycle for Menu Bar Apps

**Decision**: Use @main App with NSApplicationDelegate adapter

**Rationale**:
- `@main` SwiftUI App provides modern lifecycle
- `@NSApplicationDelegateAdaptor` bridges to AppKit for menu bar setup
- Allows hiding dock icon and window via Info.plist settings
- Maintains compatibility with SwiftUI features like Settings scenes

**Alternatives Considered**:
- Pure AppDelegate main: Rejected - loses SwiftUI lifecycle benefits
- MenuBarExtra modifier: Limited in macOS 14, less control over status item

### 5. Test Structure Mirroring

**Decision**: Test folders mirror app architectural folders

**Rationale**:
- ViewModelTests, ModelTests, ServiceTests match app structure
- Makes finding tests for a component predictable
- Follows XCTest conventions and Apple's testing guidelines
- Constitution requires 80% coverage on core logic - organized tests help track this

**Alternatives Considered**:
- Single Tests folder: Rejected - harder to navigate as test count grows
- Feature-based test folders: Rejected - app doesn't use feature-based structure

### 6. Asset Organization

**Decision**: Single Assets.xcassets with app icon, menu bar icons, and colors

**Rationale**:
- Asset catalogs handle @1x/@2x resolution automatically
- Menu bar icons need template rendering mode (single color)
- Constitution specifies three icon states: outlined, filled, grayed
- Colors catalog enables dark/light mode adaptation

**Alternatives Considered**:
- SF Symbols only: Limited customization for brand identity
- Separate asset catalogs: Unnecessary complexity for small app

## Unknowns Resolved

All technical context items were clear from the specification and constitution. No NEEDS CLARIFICATION items required external research.

## Key Dependencies Identified

| Dependency | Purpose | Version Constraint |
|------------|---------|-------------------|
| SwiftUI | UI framework for views | macOS 14+ |
| AppKit | NSStatusItem, NSPopover | macOS 14+ |
| XCTest | Testing framework | Xcode 15+ |

## Next Steps

Proceed to Phase 1: Generate data-model.md and contracts.
