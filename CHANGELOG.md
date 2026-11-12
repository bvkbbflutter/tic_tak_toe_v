# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-11-12

### Added
- **Direct Opponent Challenge System**:
  - Ability to challenge past opponents directly from the **Friends & Opponents** tab.
  - In-app incoming challenge alert banner at top of dashboard with **Accept** and **Decline** actions.
  - Dynamic 60-second challenge timer with auto-expiration and live status streaming.
  - Head-to-head records against past opponents (matches played, wins, losses).
- **Post-Match Rematch / Replay**:
  - Interactive rematch request flow on victory/defeat overlay.
  - 60-second response window for opponent with accept/decline buttons.
  - Automatic round restart with clean board reset and alternated starting turn.
  - Auto-cancel when unaccepted within 60 seconds.
- **In-Game Quick Chat**:
  - Bottom sheet of quick canned phrases (*"Good game! 🤝"*, *"Well played! 👏"*, *"Your turn! ⏳"*, *"Nice move! 🔥"*, *"Rematch? 🎮"*).
  - Floating animated in-game speech bubbles when messages are received.
- **Hardened Security Rules**:
  - Added full schema validation and access control for the `challenges` collection.
  - Added rematch state attributes (`rematchRequestedBy`, `rematchStatus`, `rematchExpiresAt`) to `matches`.
  - Deployed latest rules to Cloud Firestore.

### Fixed
- **Online Presence & "In Match" Stuck Bug**:
  - Automatically resets `isInGame: false` immediately when a match finishes.
  - Implemented `WidgetsBindingObserver` on Dashboard to restore online presence and clear stale states on app resume.
  - Added `computedIsOnline` and `computedIsInGame` to ensure players inactive for >5 minutes never show as active or in-game.

---

## [1.1.0] - 2026-11-11

### Added
- **QR Code Sharing & Scanner**:
  - Generation of room joining QR codes using `qr_flutter`.
  - Live camera QR code scanner using `mobile_scanner` (pinned to 5.2.3 for Android SDK 35/AGP 8.1.0 compatibility).
- **Matchmaking Pre-Checks & Timeout**:
  - Pre-check to verify registered active players before queuing.
  - 15-second matchmaking search timeout with "No players found" state and retry/cancel actions.
- **App Icons & Splash Screens**:
  - Custom branded 1024x1024 app icon configured across Android, iOS, and Web via `flutter_launcher_icons`.
  - Native Android launch background splash (`launch_background.xml`) and animated Flutter splash screen.
  - Modern Web index loader and favicon icons.

### Changed
- **Local Game Isolation**:
  - Offline Pass & Play matches are completely separated from online match history per user specifications.

---

## [1.0.0] - 2026-11-10

### Added
- **Neumorphic UI Design**:
  - Custom Neumorphic boxes, soft shadows, and responsive controls across all screens.
- **Online Multiplayer**:
  - Firebase Authentication with Anonymous guest and Google Sign-In.
  - Real-time turn-based Firestore game synchronization.
  - 20-second per-turn countdown timer.
  - Surrender and Draw offer mechanisms.
- **Social & Profile System**:
  - Player profiles with customizable handles, avatar selection (DiceBear bottts), bio, gender, and country.
  - Global leaderboard ranking players by wins, matches, and win rates.
  - Direct 1v1 messaging and chat between players.
- **Offline Pass & Play**:
  - Local two-player mode on a single device with winning line indicators and move reset.
