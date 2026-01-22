# Feature Specification: Cat Purr Detection

**Feature Branch**: `009-cat-purr-detection`  
**Created**: 2026-01-21  
**Status**: Draft  
**Input**: User request for ambient audio monitoring to detect cat purring using Whisper model

## Summary

Add ambient audio monitoring capability to detect cat purring sounds using the Whisper speech recognition model. When a cat's purr is detected nearby, the system can trigger keyboard lock—complementing the existing keyboard pattern detection. This provides an additional layer of cat detection that works even before the cat reaches the keyboard.

## User Scenarios & Testing

### User Story 1 - Enable Purr Detection (Priority: P1)

**As a** CatPaws user  
**I want to** enable audio-based purr detection  
**So that** my keyboard locks when my cat is nearby, even before they touch it

**Why this priority**: Core feature value—without this, the feature has no purpose.

**Independent Test**: Can be tested with a purring cat or purr audio sample.

**Acceptance Scenarios**:

1. **Given** I have granted microphone permission and purr detection is enabled,  
   **When** my cat purrs within microphone range,  
   **Then** the system detects the purr and triggers a keyboard lock.

2. **Given** purr detection is enabled but microphone permission is denied,  
   **When** I view the settings,  
   **Then** I see a clear message about required permissions with a button to open System Preferences.

3. **Given** purr detection is disabled,  
   **When** my cat purrs nearby,  
   **Then** no purr detection occurs and keyboard remains in current state.

---

### User Story 2 - Configure Purr Detection Sensitivity (Priority: P2)

**As a** CatPaws user  
**I want to** adjust purr detection sensitivity  
**So that** I can balance between false positives and detection reliability

**Why this priority**: Important for usability but not blocking core functionality.

**Independent Test**: Adjust slider and verify detection threshold changes.

**Acceptance Scenarios**:

1. **Given** I am in Settings,  
   **When** I adjust the purr sensitivity slider,  
   **Then** the detection threshold updates in real-time.

2. **Given** sensitivity is set to high,  
   **When** a quiet purr occurs,  
   **Then** the system still detects it.

3. **Given** sensitivity is set to low,  
   **When** ambient noise occurs,  
   **Then** false positives are minimized.

---

### User Story 3 - View Purr Detection Statistics (Priority: P3)

**As a** CatPaws user  
**I want to** see purr detection events in my statistics  
**So that** I can track how often my cat is detected via audio

**Why this priority**: Nice-to-have feature for engagement, not core functionality.

**Independent Test**: Trigger purr detection and verify statistics update.

**Acceptance Scenarios**:

1. **Given** purr detection events have occurred,  
   **When** I view the statistics panel,  
   **Then** I see purr detection count alongside keyboard detection stats.

---

### Edge Cases

- **Q**: What happens if multiple cats purr simultaneously?  
  **A**: Treat as single detection event; lock triggers once.

- **Q**: What if background noise resembles purring (e.g., motor, fan)?  
  **A**: Whisper model trained to distinguish; sensitivity setting helps reduce false positives.

- **Q**: What happens during system sleep/wake?  
  **A**: Audio monitoring pauses on sleep, resumes on wake with fresh state.

- **Q**: What if microphone is in use by another app?  
  **A**: Use shared audio session; gracefully handle access conflicts.

- **Q**: Battery impact of continuous monitoring?  
  **A**: Use wake-on-sound threshold to minimize processing; document battery considerations.

## Requirements

### Functional Requirements

- **FR-001**: System MUST request microphone permission before enabling purr detection.
- **FR-002**: System MUST process audio entirely on-device using Whisper model (no cloud).
- **FR-003**: System MUST detect cat purring sounds with configurable sensitivity (0.0-1.0).
- **FR-004**: System MUST create `DetectionEvent` with type `.purr` when purr is detected.
- **FR-005**: System MUST integrate purr detection with existing `LockStateManager` flow.
- **FR-006**: System SHOULD use wake-on-sound threshold to minimize battery usage.
- **FR-007**: System MUST allow users to enable/disable purr detection independently.
- **FR-008**: System MUST show microphone permission status in Settings UI.
- **FR-009**: System SHOULD display purr detection events in statistics view.
- **FR-010**: System MUST pause audio monitoring when app is inactive or system sleeps.

### Non-Functional Requirements

- **NFR-001**: Purr detection latency MUST be under 500ms from sound to lock trigger.
- **NFR-002**: Audio processing MUST NOT cause noticeable UI lag.
- **NFR-003**: Whisper model size SHOULD be under 100MB (use whisper-tiny or base).
- **NFR-004**: Battery usage SHOULD be minimized through efficient audio sampling.

### Key Entities

- **DetectionType**: Extended enum with `.purr` case
- **Configuration**: Extended with purr detection settings
- **AudioMonitor**: New service for microphone capture
- **PurrDetectionService**: New service for Whisper-based detection
- **PermissionType**: Extended with `.microphone` case

## Success Criteria

### Measurable Outcomes

- **SC-001**: Purr detection successfully triggers on real cat purring within 500ms.
- **SC-002**: False positive rate below 5% in normal household environment.
- **SC-003**: Microphone permission flow works correctly on macOS 14+.
- **SC-004**: Purr events appear correctly in statistics with accurate counts.
- **SC-005**: All unit tests pass with >80% code coverage for new services.
- **SC-006**: No memory leaks during extended audio monitoring sessions.

## Assumptions

- User has macOS 14.0+ with microphone hardware available.
- User consents to microphone access for cat detection purposes.
- WhisperKit or similar framework available for on-device Whisper inference.
- Cat purring frequency range (25-150 Hz) is distinguishable by Whisper model.
- Existing `LockStateManager` can accept detection events from multiple sources.
