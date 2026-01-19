# CatPaws Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-19

## Active Technologies

- Swift 5.9+, Xcode 15+ + SwiftUI, AppKit (NSEvent for global keyboard monitoring), Accessibility APIs (CGEvent) (002-cat-keyboard-lock)
- UserDefaults (configuration only - debounce timing, cooldown duration) (002-cat-keyboard-lock)
- Swift 5.9+, Xcode 15+ + SwiftUI (UI), AppKit (NSStatusItem, NSPanel, NSEvent for global monitoring), ServiceManagement (SMAppService for login items), Carbon (TISGetInputSourceProperty for keyboard layout detection) (003-app-polish-improvements)
- UserDefaults (configuration and statistics persistence) (003-app-polish-improvements)
- Swift 5.9+, Xcode 15+ + SwiftUI, AppKit (NSWindow, NSStatusItem) (004-onboarding-ui-fixes)
- UserDefaults (configuration/state persistence) (004-onboarding-ui-fixes)
- Swift 5.9+, Xcode 15+ + SwiftUI, AppKit, CoreGraphics (CGPreflightListenEventAccess, AXIsProcessTrusted) (005-permissions-settings-enhancements)
- Swift 5.9+, Xcode 15+ + SwiftUI, AppKit (for NSStatusItem/menu bar), XCTest (001-swift-project-structure)

## Project Structure

```text
CatPaws/CatPaws/
├── App/                 # App entry point and delegates
├── Configuration/       # Entitlements and Info.plist
├── MenuBar/            # Menu bar UI components
├── Models/             # Data models and state
├── Resources/          # Assets and localization
├── Services/           # Business logic services
├── Utilities/          # Helper utilities
├── ViewModels/         # MVVM view models
└── Views/              # SwiftUI views

CatPawsTests/           # Unit and integration tests
CatPawsUITests/         # UI tests
specs/                  # Feature specifications
```

## Commands

```bash
# Build
xcodebuild -scheme CatPaws -configuration Debug build

# Test
xcodebuild -scheme CatPaws -configuration Debug test

# Run SwiftLint
swiftlint

# Reset user configuration
defaults delete com.corti.CatPaws

# Create release build
xcodebuild build -scheme CatPaws -destination 'platform=macOS' -configuration Release

# Copy release build to Apps folder
cp -R ~/Library/Developer/Xcode/DerivedData/CatPaws-*/Build/Products/Release/CatPaws.app /Applications/
```

## Code Style

- Swift 5.9+: Follow Apple Swift API Design Guidelines
- Use SwiftUI for UI components, AppKit only when SwiftUI lacks functionality
- Use async/await for asynchronous operations
- MVVM architecture with ObservableObject view models
- Prefix UserDefaults keys with `catpaws.`

## Recent Changes

- 005-permissions-settings-enhancements: Added Swift 5.9+, Xcode 15+ + SwiftUI, AppKit, CoreGraphics (CGPreflightListenEventAccess, AXIsProcessTrusted)
- 004-onboarding-ui-fixes: Added Swift 5.9+, Xcode 15+ + SwiftUI, AppKit (NSWindow, NSStatusItem)
- 003-app-polish-improvements: Added Swift 5.9+, Xcode 15+ + SwiftUI (UI), AppKit (NSStatusItem, NSPanel, NSEvent for global monitoring), ServiceManagement (SMAppService for login items), Carbon (TISGetInputSourceProperty for keyboard layout detection)
- 002-cat-keyboard-lock: Added Swift 5.9+, Xcode 15+ + SwiftUI, AppKit (NSEvent for global keyboard monitoring), Accessibility APIs (CGEvent)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
