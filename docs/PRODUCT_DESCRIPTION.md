# Spelling Test iOS App – "SpellPlay"

## TL;DR

A simple iOS app enabling parents to create custom spelling tests for their children in a Duolingo-like interface. Children can practice spelling daily, listening to each word's pronunciation, making studying engaging and interactive.

## Goals

### Business Goals

- Achieve 500 downloads and 200 active users in the first three months.
- Average user session length above 5 minutes.
- Establish strong App Store reviews (4.5+ rating).

### User Goals

- Allow parents to easily create and edit spelling lists.
- Enable kids to practice spelling in a gamified, fun way.
- Make word pronunciation clear and accessible for effective learning.

### Non-Goals

- No group/classroom management in MVP.
- No advanced analytics for parents on launch.
- No Android version at first.

## User Stories

### Parent

- As a parent, I want to create a new spelling test by entering a list of words, so my child can practice them.
- As a parent, I want to review and edit my saved spelling lists, so I can update words as needed.
- As a parent, I want to see a simple summary of test completion, so I know my child is practicing.

### Child

- As a child, I want to practice spelling words in a game-like format, so learning is fun.
- As a child, I want to listen to the pronunciation of each word before spelling, so I know what to type.
- As a child, I want to track my daily practice streak, so I feel motivated.

## Functional Requirements

### Parent Admin (Priority: High)

- **Create/Edit Tests**: Enter multiple words per test.
- **Review Saved Tests**: View, edit, and delete word lists.

### Spelling Practice (Priority: High)

- **Daily Practice Flow**: Child selects a test, listens to words, and enters spellings.
- **Audio Playback**: Button to play the word pronunciation using TTS.

### Gamification (Priority: Medium)

- **Streak Tracking**: Visual indicator of practice streak.
- **Simple Success Feedback**: Celebrations for correct/complete practice.

## User Experience

### Entry Point & First-Time User Experience

- First launch presents choice: "I am a Parent" or "I am a Kid."
- Parent onboarding explains how to create a test; prompts to enter a word list.
- Kid onboarding briefly introduces practice flow.

### Core Experience

**Step 1**: The parent logs in/enters the app and creates a new test.
- Clearly labeled fields for word entry.
- Option to save and name the test.
- Optionally, preview/listen to word using TTS.

**Step 2**: The child selects a test to practice.
- Friendly, simple UI—a test list and "Start Practice" button.

**Step 3**: Child is presented with a word (audio plays automatically or by pressing a button).
- Kid types the spelling and submits.
- App checks accuracy, provides instant feedback.

**Step 4**: Practice session summary at completion (score, streak).

### Advanced Features & Edge Cases

- If no spelling list exists, prompt the parent to create one.
- If device offline, gracefully disable TTS or show fallback.

### UI/UX Highlights

- High-contrast, kid-friendly visuals.
- Large touch targets for young fingers.
- Simple, intuitive navigation; minimal text for kids.

## Narrative

Sarah is a busy parent who wants her daughter to build strong spelling skills. After struggling to keep her daughter engaged with paper lists, Sarah downloads "SpellPlay." In less than a minute, she creates a list of this week's spelling words. Her daughter, Mia, opens the app, easily finds her test, and starts practicing. With each word pronounced out loud in a friendly voice, Mia types in her answers. The colorful rewards keep her coming back every day, and Sarah quickly sees Mia's progress. Their routine is transformed—no reminders needed, and spelling time is now a highlight, not a chore.

## Success Metrics

### User-Centric Metrics

- Number of practice sessions per week per child.
- Average daily active users (DAU).
- Practice streak retention (day-over-day repeat usage).

### Business Metrics

- App Store rating and reviews.
- Downloads and active installs.

### Technical Metrics

- Session crash-free rate (>99%).
- Text-to-speech latency under 2 seconds per word.

## Tracking Plan

- Test created (parent-side).
- Practice session started/completed (child-side).
- Streaks and daily activity.
- Audio play button use.

## Technical Considerations

### Technical Needs

- iOS client: Swift/SwiftUI app.
- Local database for storing tests and progress.
- Native Text-to-Speech for audio playback.

### Integration Points

- No third-party integrations for MVP.

### Data Storage & Privacy

- All data stored locally on device.
- No cloud or account required at launch.
- Optional: PIN lock for parent area.

### Scalability & Performance

- Targeting single-family use; must run smoothly on common iOS devices.

### Potential Challenges

- Ensuring high-quality, natural TTS pronunciation.
- Maintaining child privacy and safety within the app.

## Milestones & Sequencing

### Project Estimate

- Small: 1–2 weeks for Lean MVP.

### Team Size & Composition

- Extra-small: 1–2 people (Product/Design, iOS Engineer).

### Suggested Phases

#### MVP Build (2 weeks)

**Key Deliverables:**
- Parent creates, edits, and saves tests.
- Child practices with audio pronunciation and receives feedback.
- Streak and basic stats.

**Dependencies:** Apple TTS, device capabilities.
