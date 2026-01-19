# Data Model: Onboarding UI Fixes

**Branch**: `004-onboarding-ui-fixes` | **Date**: 2026-01-19

## Overview

This feature involves UI polish fixes only. No data model changes are required.

## Affected Entities

None. The fixes modify:
- View layouts and sizing (SwiftUI views)
- Static content (text, key labels)
- Window configuration (AppDelegate)

## Existing Entities (Unchanged)

### OnboardingStep (enum)

Existing 5-step flow remains unchanged:
- `.welcome` (0)
- `.permissionExplanation` (1)
- `.grantPermission` (2)
- `.testDetection` (3)
- `.complete` (4)

### OnboardingState (struct)

Existing persistence structure remains unchanged:
- `hasCompletedOnboarding: Bool`
- `wasSkipped: Bool`
- `currentStep: OnboardingStep`

## UI Configuration Changes

| Constant | Current Value | New Value | Location |
|----------|---------------|-----------|----------|
| Onboarding window height | 400pt | 500pt | AppDelegate.swift, OnboardingView.swift |
| Test key pattern | "A", "S", "D", "F" | "S", "E", "D" | OnboardingView.swift |
| Test key layout | HStack (horizontal) | VStack+HStack (triangular) | OnboardingView.swift |
