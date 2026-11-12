# 🎮 Tic Tac Toe - Online & Offline Multiplayer (Flutter)

A modern, full-featured **Tic Tac Toe multiplayer gaming platform** built with **Flutter**, **Firebase**, and **Riverpod**, designed with a polished **Neumorphic UI** and supporting **Android**, **iOS**, and **Web**.

---

## ✨ Features

### 🕹️ Game Modes
- **Offline Pass & Play (Local Multiplayer)**: Play locally with a friend on the same device. No network required, with zero match history clutter.
- **Online 1v1 Matchmaking**: Real-time matchmaking queue with registered player checks and a friendly 15-second timeout dialog with retry/cancel actions.
- **Private Room Codes**: Create private rooms and join with a 6-digit room code.
- **QR Code Instant Join**:
  - Host generates a unique game QR code (`qr_flutter`).
  - Opponents scan the QR code using their device camera (`mobile_scanner`) to join instantly.
- **Direct Opponent Challenge System**:
  - Challenge online players or past opponents directly from the **Friends & Opponents** tab.
  - In-app challenge popup banner with **Accept** / **Decline** options and a 60-second expiration timer.

### ⚡ Live In-Game Experience
- **Real-Time Board Sync**: Moves synchronize instantaneously via Cloud Firestore.
- **Turn Timer**: 20-second countdown per move to keep gameplay fast-paced.
- **Interactive Reactions & Chat**:
  - Quick emoji reactions with floating animated emojis.
  - Canned quick chat messages (*"Good game! 🤝"*, *"Well played! 👏"*, *"Your turn! ⏳"*, *"Nice move! 🔥"*, *"Rematch? 🎮"*).
- **Draw Offers & Surrender**: Request mutual draws or concede with proper win/loss record updates.
- **Rematch / Replay System**:
  - Request a rematch directly from the victory/defeat screen.
  - 60-second countdown with opponent prompt (Accept/Decline) and automatic cancellation on timeout.
  - Seamless round reset: clears board, alternates starter, and resumes gameplay without leaving the screen.

### 👤 Profile & Social Features
- **Firebase Authentication**: Anonymous Guest login and Google Sign-In.
- **Player Profiles**: Unique Player ID (`TTT-xxxxx`), username, custom display name, bio, gender, and country.
- **CORS-Safe Avatars**: Pre-configured DiceBear avatar styles optimized for Android, iOS, and Web.
- **Real-Time Presence**: Dynamic online indicator and in-match status tracking.
- **Global Leaderboard**: Live rankings by wins, total matches, win streaks, and win rate.
- **Direct 1v1 Chat**: Private messaging between players.

### 🔒 Security & Architecture
- **Clean Architecture**: Structured into Presentation (UI + Controllers), Domain/State (Riverpod), and Data (Models, Repositories, Services).
- **Hardened Cloud Firestore Security Rules**: Complete schema validation, participant authorization, and field whitelisting.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, Dart 3.x)
- **State Management**: [Riverpod (flutter_riverpod)](https://pub.dev/packages/flutter_riverpod)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend & Database**: [Firebase Auth](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore)
- **Offline Storage**: [Hive](https://pub.dev/packages/hive) / [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **Camera & Scanning**: [mobile_scanner](https://pub.dev/packages/mobile_scanner) (v5.2.3, compatible with Android SDK 35/36)
- **QR Generation**: [qr_flutter](https://pub.dev/packages/qr_flutter)
- **Icons & Splash**: [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons), Android native launch drawables

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19+)
- [Android Studio / Xcode](https://docs.flutter.dev/get-started/install) for mobile development
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)

### 2. Clone and Install Dependencies
```bash
git clone https://github.com/your-username/tic_tak_toe_v.git
cd tic_tak_toe_v
flutter pub get
```

### 3. Firebase Configuration
The project is configured with FlutterFire (`firebase_options.dart`).
Ensure your Firebase project has:
1. **Authentication**: Enable *Anonymous* and *Google* providers.
2. **Cloud Firestore**: Create a Firestore database.

To deploy the hardened security rules:
```bash
firebase deploy --only firestore:rules
```

### 4. Running the App
- **Android**:
  ```bash
  flutter run -d android
  ```
- **iOS**:
  ```bash
  flutter run -d ios
  ```
- **Web**:
  ```bash
  flutter run -d chrome
  ```

### 5. Building for Production
- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **Web App**:
  ```bash
  flutter build web --release
  ```

---

## 🧪 Testing & Code Quality

Run tests:
```bash
flutter test
```

Analyze static code:
```bash
flutter analyze
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
