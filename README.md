# CatPaws 🐾

A macOS menu bar app that detects when a cat walks on your keyboard and automatically locks input to prevent unwanted keystrokes.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Smart Cat Detection** - Detects cat-like keyboard patterns (multiple adjacent keys pressed simultaneously)
- **Automatic Keyboard Lock** - Instantly blocks all keyboard input when a cat is detected
- **Visual Notification** - Shows a friendly popup when the keyboard is locked
- **Auto Unlock** - Automatically unlocks when the cat leaves the keyboard
- **Manual Override** - Click the notification to immediately unlock
- **Statistics Tracking** - See how many times your cat has visited your keyboard
- **Launch at Login** - Optionally start CatPaws when you log in
- **Configurable Sensitivity** - Adjust detection thresholds to match your cat's behavior

## Screenshots

*Coming soon*

## Installation

### Download

Download the latest release from the [Releases](https://github.com/TechPreacher/CatPaws/releases) page.

1. Download `CatPaws-x.x.x.dmg`
2. Open the DMG file
3. Drag CatPaws to your Applications folder
4. Launch CatPaws from Applications

### Permissions

CatPaws requires **Input Monitoring** permission to detect keyboard events:

1. On first launch, you'll be prompted to grant access
2. Go to **System Settings** → **Privacy & Security** → **Input Monitoring**
3. Enable CatPaws in the list

## Usage

Once running, CatPaws appears as a paw icon in your menu bar:

- **🐾** - Active and monitoring
- Click the icon to access settings, statistics, and quit

### How Detection Works

CatPaws monitors keyboard input for patterns that indicate a cat:

- 3+ adjacent keys pressed simultaneously (single paw)
- Multiple clusters of keys across the keyboard (multiple paws)
- 10+ keys pressed at once (cat sitting on keyboard)

When detected, the keyboard locks for a brief period. If the cat-like pattern persists, it stays locked. Once the keys are released, the keyboard automatically unlocks.

### Settings

- **Detection Sensitivity** - Adjust how sensitive the detection is
- **Lock Duration** - How long to wait before auto-unlocking
- **Launch at Login** - Start CatPaws automatically
- **Show Notifications** - Toggle visual feedback

## Building from Source

### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build Steps

```bash
# Clone the repository
git clone https://github.com/TechPreacher/CatPaws.git
cd CatPaws

# Open in Xcode
open CatPaws/CatPaws.xcodeproj

# Or build from command line
cd CatPaws
xcodebuild build -scheme CatPaws -configuration Debug
```

### Creating a Release Build

Use the provided build script to create a signed and notarized release:

```bash
./scripts/build-release.sh
```

This will:
1. Build a Release configuration
2. Sign with Developer ID
3. Submit for Apple notarization
4. Create DMG and ZIP packages

## Project Structure

```
CatPaws/
├── App/                 # App entry point and delegates
├── Configuration/       # Entitlements and Info.plist
├── MenuBar/            # Menu bar UI components
├── Models/             # Data models and state
├── Resources/          # Assets and localization
├── Services/           # Business logic services
├── ViewModels/         # MVVM view models
└── Views/              # SwiftUI views
```

## How It Works

1. **Keyboard Monitoring** - Uses macOS Input Monitoring APIs to observe key events
2. **Pattern Detection** - Analyzes key timing and adjacency to identify cat patterns
3. **Input Blocking** - Uses CGEvent tap to intercept and block keyboard events
4. **State Management** - SwiftUI-based reactive state for UI updates

## Privacy

CatPaws:
- Does **not** record or transmit any keystrokes
- Does **not** connect to the internet
- Only monitors key *patterns*, not actual characters typed
- All processing happens locally on your Mac

See our full [Privacy Policy](https://catpaws.corti.com/privacy-policy.html).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by every cat owner who has had their work interrupted by curious paws
- Built with SwiftUI and love for cats 🐱
