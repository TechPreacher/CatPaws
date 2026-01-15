# Data Model: Swift Project Structure Initialization

**Feature**: 001-swift-project-structure
**Date**: 2026-01-15

## Overview

This feature focuses on project structure initialization. The data model describes the structural entities (files, folders, targets) rather than runtime data models. Runtime models will be defined in subsequent features.

## Structural Entities

### Xcode Project

| Attribute | Type | Description |
|-----------|------|-------------|
| Name | String | "CatPaws" |
| Organization | String | Developer/team identifier |
| Bundle ID | String | Reverse domain (e.g., com.example.CatPaws) |
| Deployment Target | Version | macOS 14.0 |
| Swift Version | Version | 5.9 |

### App Target: CatPaws

| Attribute | Type | Description |
|-----------|------|-------------|
| Product Type | Enum | Application (.app bundle) |
| Platform | Enum | macOS |
| UI Framework | Enum | SwiftUI + AppKit |
| Lifecycle | Enum | SwiftUI App (@main) |
| Sandbox | Boolean | true (App Store requirement) |
| Dock Icon | Boolean | false (menu bar app) |

**Entitlements**:
- `com.apple.security.app-sandbox`: true
- `com.apple.security.device.input-monitoring`: true

### Test Target: CatPawsTests

| Attribute | Type | Description |
|-----------|------|-------------|
| Product Type | Enum | Unit Test Bundle |
| Host Application | Reference | CatPaws |
| Framework | Enum | XCTest |

### Test Target: CatPawsUITests

| Attribute | Type | Description |
|-----------|------|-------------|
| Product Type | Enum | UI Test Bundle |
| Host Application | Reference | CatPaws |
| Framework | Enum | XCTest |

## Folder Structure Entities

### Source Groups (CatPaws/)

| Group | Purpose | Initial Contents |
|-------|---------|------------------|
| App | Entry point, lifecycle | CatPawsApp.swift, AppDelegate.swift |
| MenuBar | Status item management | StatusItemManager.swift, MenuBarView.swift |
| Views | SwiftUI views | PopoverView.swift, SettingsView.swift |
| ViewModels | MVVM view models | AppViewModel.swift |
| Models | Data structures | AppState.swift |
| Services | Business logic | (placeholder .gitkeep) |
| Utilities | Extensions, helpers | (placeholder .gitkeep) |
| Resources | Assets, strings | Assets.xcassets, Localizable.strings |
| Configuration | Plist, entitlements | Info.plist, CatPaws.entitlements |

### Test Groups (CatPawsTests/)

| Group | Purpose | Initial Contents |
|-------|---------|------------------|
| ViewModelTests | ViewModel unit tests | (placeholder .gitkeep) |
| ModelTests | Model unit tests | (placeholder .gitkeep) |
| ServiceTests | Service unit tests | (placeholder .gitkeep) |

### UI Test Groups (CatPawsUITests/)

| Group | Purpose | Initial Contents |
|-------|---------|------------------|
| MenuBarTests | Menu bar UI tests | (placeholder .gitkeep) |

## Asset Catalog Structure

### Assets.xcassets

| Asset | Type | Variants |
|-------|------|----------|
| AppIcon | App Icon | 16, 32, 128, 256, 512 pt @1x/@2x |
| MenuBarIcon | Image Set | Template, outlined state |
| MenuBarIconActive | Image Set | Template, filled state |
| MenuBarIconDisabled | Image Set | Template, grayed state |
| AccentColor | Color Set | Light/dark mode |

## Relationships

```
CatPaws.xcodeproj
├── contains → CatPaws (App Target)
│   ├── references → Info.plist
│   ├── references → CatPaws.entitlements
│   └── includes → Assets.xcassets
├── contains → CatPawsTests (Test Target)
│   └── tests → CatPaws
└── contains → CatPawsUITests (UI Test Target)
    └── tests → CatPaws
```

## Validation Rules

1. **Bundle ID**: Must be unique, reverse-domain format
2. **Deployment Target**: Must be macOS 14.0 or later
3. **Entitlements**: Must include sandbox and input-monitoring
4. **Info.plist**: Must set LSUIElement=true (hide dock icon)
5. **Test Targets**: Must have host application set to CatPaws
