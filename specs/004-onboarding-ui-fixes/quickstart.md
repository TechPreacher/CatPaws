# Quickstart: Onboarding UI Fixes

**Branch**: `004-onboarding-ui-fixes` | **Date**: 2026-01-19

## Prerequisites

- Xcode 15+
- macOS 14+
- Project cloned and branch checked out

## Testing the Fixes

### 1. Reset Onboarding State

Before testing, reset the onboarding state to see the first-run experience:

```bash
defaults delete com.corti.CatPaws
```

### 2. Build and Run

1. Open `CatPaws/CatPaws.xcodeproj` in Xcode
2. Select the CatPaws scheme
3. Press Cmd+R to build and run

### 3. Verify Fixes

#### Fix 1: Window Height (Step 2)
- Navigate to Step 2 (Permission Explanation)
- Verify all content is visible without clipping
- All three green checkmark items should be fully visible

#### Fix 2: CatPaws in Input Monitoring
- Navigate to Step 3 (Grant Permission)
- Click "Open System Settings"
- Verify CatPaws appears in the Input Monitoring list
- If not listed, the app should prompt for permission on first event tap attempt

#### Fix 3: Text Overflow (Step 4)
- Navigate to Step 4 (Test Detection)
- Verify the instruction text is fully visible
- Should read: "Let's make sure CatPaws is working correctly. Press these three keys together:"

#### Fix 4: Test Key Pattern
- On Step 4, verify the keys are displayed in triangular arrangement:
  ```
      [E]
    [S] [D]
  ```
- Press S, E, D simultaneously to trigger detection

#### Fix 5: Quit Option in Permission Required State
- Revoke CatPaws permission in System Settings (toggle OFF)
- Click the CatPaws menu bar icon
- Verify "Quit CatPaws" button is visible in the dropdown
- Click Quit to verify it terminates the app

### 4. Run Tests

```bash
xcodebuild test -scheme CatPaws -destination 'platform=macOS'
```

### Key Files to Review

| File | Purpose |
|------|---------|
| `CatPaws/App/AppDelegate.swift` | Window size configuration |
| `CatPaws/Views/OnboardingView.swift` | Steps 2, 4 content and key pattern |
| `CatPaws/Views/PermissionGuideView.swift` | Menu bar permission guidance + Quit button |
