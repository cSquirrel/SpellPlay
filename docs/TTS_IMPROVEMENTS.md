# TTS Error and Offline Handling Implementation

## Overview
Enhance TTSService to properly detect TTS availability, handle errors, manage audio session interruptions, and provide fallback UI when TTS is unavailable.

## Implementation Steps

### 1. Enhance TTSService.swift
- Replace placeholder `checkAvailability()` with real voice availability check
- Add error handling delegate methods (`speechSynthesizer:didStart:`, error handling)
- Add audio session interruption handling via AVAudioSession notifications
- Update `isAvailable` based on actual errors and interruptions
- Add error message property for user feedback

### 2. Update PracticeView.swift
- Add fallback UI when TTS is unavailable (display word text prominently instead of audio button)
- Show message when audio is unavailable
- Handle TTS unavailable state in round transition view

### 3. Update CreateTestView.swift and EditTestView.swift
- Handle TTS unavailable state for word preview buttons
- Show fallback when TTS fails

## Files to Modify
- `SpellPlay/Services/TTSService.swift` - Core TTS service enhancements
- `SpellPlay/Features/Child/PracticeView.swift` - Fallback UI for practice
- `SpellPlay/Features/Parent/CreateTestView.swift` - Fallback for word preview
- `SpellPlay/Features/Parent/EditTestView.swift` - Fallback for word preview

## Implementation Todos

1. **tts-availability-check** - Replace placeholder checkAvailability() with real voice availability detection using AVSpeechSynthesisVoice.speechVoices()
2. **tts-error-handling** - Add error handling delegate methods (speechSynthesizer:didStart:, speechSynthesizer:didContinue:, speechSynthesizer:didPause:) and update isAvailable on errors
3. **audio-session-interruptions** - Add AVAudioSession interruption notifications to handle phone calls and other audio apps
4. **practice-view-fallback** - Add fallback UI in PracticeView to display word text prominently when TTS is unavailable
5. **parent-views-fallback** - Update CreateTestView and EditTestView to handle TTS unavailable state for word preview buttons

