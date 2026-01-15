# Quickstart: Swift Project Structure Initialization

**Feature**: 001-swift-project-structure
**Date**: 2026-01-15

## Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 15.0 or later
- Apple Developer account (for signing)

## Getting Started

### 1. Clone and Open

```bash
git clone <repository-url>
cd CatPaws
open CatPaws/CatPaws.xcodeproj
```

### 2. Configure Signing

1. Select the CatPaws project in Xcode navigator
2. Select the CatPaws target
3. Go to "Signing & Capabilities" tab
4. Select your development team
5. Ensure "Automatically manage signing" is checked

### 3. Build and Run

```bash
# Command line
xcodebuild -project CatPaws/CatPaws.xcodeproj -scheme CatPaws -configuration Debug build

# Or use Xcode
# Press Cmd+R to build and run
```

### 4. Verify Menu Bar App

After running:
1. The app should NOT appear in the Dock
2. A paw icon should appear in the menu bar
3. Clicking the icon should show a popover

### 5. Run Tests

```bash
# Command line
xcodebuild test -project CatPaws/CatPaws.xcodeproj -scheme CatPaws -destination 'platform=macOS'

# Or in Xcode
# Press Cmd+U to run all tests
```

## Project Structure Overview

```
CatPaws/
├── CatPaws.xcodeproj/     # Open this in Xcode
├── CatPaws/               # Main app source
│   ├── App/               # Entry point (@main)
│   ├── MenuBar/           # Status item code
│   ├── Views/             # SwiftUI views
│   ├── ViewModels/        # MVVM view models
│   ├── Models/            # Data models
│   ├── Services/          # Business logic
│   ├── Utilities/         # Helpers
│   ├── Resources/         # Assets
│   └── Configuration/     # Plist, entitlements
├── CatPawsTests/          # Unit tests
└── CatPawsUITests/        # UI tests
```

## Adding New Code

| To add... | Place in... | Example |
|-----------|-------------|---------|
| New view | `Views/` | `SettingsDetailView.swift` |
| New view model | `ViewModels/` | `SettingsViewModel.swift` |
| New data model | `Models/` | `UserPreferences.swift` |
| New service | `Services/` | `KeyboardMonitor.swift` |
| Helper/extension | `Utilities/` | `NSEvent+Extensions.swift` |
| Unit test | `CatPawsTests/<Category>Tests/` | `ViewModelTests/AppViewModelTests.swift` |

## Common Tasks

### Add a new Settings option

1. Add property to `Models/AppState.swift`
2. Add UI in `Views/SettingsView.swift`
3. Add binding in `ViewModels/AppViewModel.swift`
4. Add test in `CatPawsTests/ViewModelTests/`

### Modify menu bar behavior

1. Update `MenuBar/StatusItemManager.swift`
2. Update icon assets in `Resources/Assets.xcassets/`
3. Add UI test in `CatPawsUITests/MenuBarTests/`

## Troubleshooting

### App doesn't appear in menu bar
- Check Info.plist has `LSUIElement` set to `YES`
- Verify `StatusItemManager` is initialized in `AppDelegate`

### Build fails with signing error
- Ensure development team is selected in Signing & Capabilities
- Check bundle identifier is unique

### Tests don't run
- Ensure test targets have CatPaws as host application
- Check test files are members of correct target
