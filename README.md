# LeetStreak — Android LeetCode Streak Companion

**LeetStreak** is a personal LeetCode streak-maintenance Android companion application built with Flutter, Material 3, Riverpod, and native Kotlin integrations.

When you're busy with college exams, travel, or work commitments, LeetStreak allows you to maintain your daily LeetCode activity by selecting and submitting previously accepted solutions stored in your private local library — completely from your phone without opening a laptop.

---

## 🌟 Key Features

### 1. Main Dashboard & Contribution Heatmap
- **Real LeetCode Heatmap**: Visualizes your actual submission calendar grid fetched directly from LeetCode's public GraphQL endpoint. Accurately parses timestamp-based daily submission counts with timezone awareness (UTC and Indian Standard Time).
- **Streak & Activity Metrics**: Displays current streak (flame badge), total active days, total saved solutions, and breakdown across Easy, Medium, and Hard.
- **Today's Activity Status**: Instant visual feedback indicating whether today's streak is secured (`✓ Secured`) or at risk (`⚠ At Risk`).
- **Prominent Action CTA**: One-tap "Save Today's Streak" button.
- **Recently Added Solutions**: Quick access to newly saved problems with difficulty badges and timestamps.
- **Sync & Demo Mode**: Pull down to refresh your live LeetCode stats, or toggle Demo Mode to explore the app with realistic sample data without requiring an active LeetCode handle.

### 2. Private Local Solution Library (SQLite)
- **Local-First Privacy**: All problems and solutions are persisted locally on-device in SQLite (`sqflite`). No external accounts, servers, Supabase, or Firebase required.
- **Manual Problem Entry**: Add problem title, LeetCode problem ID, problem slug, URL, difficulty (Easy, Medium, Hard), programming language, source code, and notes.
- **File Import**: Seamlessly import code files (`.py`, `.cpp`, `.java`, `.js`, `.ts`, `.go`, `.rs`, `.kt`, `.c`, `.cs`, `.swift`, `.txt`). Automatically detects the language from the file extension.
- **Pre-populated Accepted Solutions**: Comes pre-loaded with classic accepted solutions (Two Sum, Valid Parentheses, Merge Two Sorted Lists, Best Time to Buy and Sell Stock, Reverse Linked List, Maximum Subarray, Binary Search, Invert Binary Tree).
- **Search & Multi-criteria Filtering**: Search by keyword or problem number; filter by difficulty and programming language.
- **Code Safety Guarantee**: The original saved source code is **never overwritten** during submission attempts.

### 3. Intelligent Random Problem Selection
- **Cooldown Window**: Configurable cooldown period (default 7 days) to avoid repeatedly submitting the same problem when alternatives exist.
- **Language Preference**: Option to prioritize your preferred programming language (e.g. Python 3, Java, C++).
- **Least-Recently-Used Fallback**: If all problems have been submitted within the cooldown window, falls back to the least recently submitted solution.
- **Re-Roll System**: Preview the problem, difficulty, language, and syntax-highlighted source code with an instant "Pick Another" re-roll button.
- **Explicit Confirmation**: Requires explicit confirmation before initiating the submission workflow.

### 4. Authenticated Browser Submission Workflow
- **Local WebView Integration**: Embeds an authenticated in-app Android browser (`webview_flutter`).
- **Zero Cookie Leakage**: Session credentials and cookies remain strictly inside the local Android WebView cookie store; never transmitted to any external server.
- **Smart Assistance**: Automatically copies the solution code to your clipboard and navigates directly to `https://leetcode.com/problems/<slug>/`.
- **Verdict Verification**: Only records a streak save upon a genuine `Accepted` verdict. Handles `Wrong Answer`, `Runtime Error`, and pending submissions distinctly.

### 5. Android Home Screen Widget
- **Compact Native Widget**: Implemented with native Android `AppWidgetProvider` (`StreakWidgetProvider.kt`) and `RemoteViews`.
- **Live Glanceable Data**: Shows current streak count with flame icon, today's status, and mini 5-day activity dots.
- **One-Tap Quick Save**: "⚡ Save Streak" button on the widget launches the app directly into the streak saver flow.
- **Offline Reliability**: Reads cached data from `FlutterSharedPreferences` for instant offline rendering.

### 6. Android Quick Settings Tile
- **Native TileService**: Implemented in Kotlin (`SaveStreakTileService.kt`).
- **Discoverable**: Appears in the Android notification shade Quick Settings tile editor as "Save Streak".
- **Dynamic State**: Highlights active when today's streak is secured, or inactive with an "At Risk" subtitle if you still need to solve a problem today.
- **Safe Launch**: Tapping the tile expands the app into the confirmation screen; never silently submits code in the background.

### 7. Submission History
- Detailed log of all submission attempts with problem title, timestamp, language, and verdict badge (`Accepted`, `Wrong Answer`, `Runtime Error`, `Time Limit Exceeded`, `Pending`, `Failed`).
- Filter history by verdict.
- Clear history option.

### 8. Data Management & Settings
- Export and import complete library backups in structured JSON format.
- Customizable cooldown period slider (1 to 30 days).
- Preferred programming language selector.
- Theme: Dark charcoal/near-black theme (`#0F1117`), dark grey surfaces (`#181A22`), and LeetCode orange accent (`#FFA116`).

---

## 🏗️ Architecture

```
lib/
├── main.dart                                   # App entry point & provider scopes
├── core/
│   ├── theme/
│   │   ├── app_colors.dart                     # Near-black surfaces, LeetCode orange, GitHub green heatmap
│   │   └── app_theme.dart                      # Material 3 dark theme specifications
│   ├── constants/
│   │   └── app_constants.dart                  # URLs, method channel names, storage keys
│   ├── utils/
│   │   └── time_utils.dart                     # UTC & Indian Standard Time timezone formatting
│   └── native/
│       └── native_channel.dart                 # Platform Channel bridge to native Widget & Tile
├── data/
│   ├── models/
│   │   ├── difficulty.dart                     # Easy, Medium, Hard enum & styling
│   │   ├── language.dart                       # Python, Java, C++, etc. metadata
│   │   ├── saved_problem.dart                  # Problem library entity model
│   │   ├── submission_attempt.dart             # Submission attempt & verdict model
│   │   ├── user_profile.dart                   # Public LeetCode profile model
│   │   └── heatmap_day.dart                    # Calendar day submission intensity model
│   ├── local/
│   │   ├── database_helper.dart                # SQLite database open & migrations
│   │   ├── default_problems.dart               # Pre-populated accepted solutions
│   │   ├── problem_dao.dart                    # Problem CRUD & intelligent selection
│   │   ├── submission_dao.dart                 # Submission history DAO
│   │   └── heatmap_dao.dart                    # Heatmap cache DAO
│   └── services/
│       ├── leetcode_api_service.dart           # LeetCode public GraphQL client & parser
│       └── preference_service.dart             # SharedPreferences storage wrapper
├── providers/
│   ├── app_state_providers.dart                # Base service providers
│   ├── settings_providers.dart                 # Settings state notifier
│   ├── problem_providers.dart                  # Problem library & random selection notifier
│   ├── submission_providers.dart               # History notifier & today streak check
│   └── heatmap_providers.dart                  # Profile & heatmap synchronization notifier
└── ui/
    ├── screens/
    │   ├── main_navigation_screen.dart         # Bottom nav: Dashboard, Library, History, Settings
    │   ├── dashboard_screen.dart               # Main dashboard with stats & heatmap
    │   ├── library_screen.dart                 # Solution search & filter catalog
    │   ├── problem_detail_screen.dart          # Code view with syntax highlighting
    │   ├── edit_problem_screen.dart            # Add/edit form with file picker
    │   ├── history_screen.dart                 # Submission attempt audit log
    │   ├── settings_screen.dart                # Account & app preferences
    │   ├── streak_saver_flow_screen.dart       # Problem selection & confirmation flow
    │   └── authenticated_submission_webview_screen.dart # In-app LeetCode browser & verdict recorder
    └── widgets/
        ├── heatmap_widget.dart                 # 52-week horizontal calendar grid
        ├── streak_flame_badge.dart             # Glowing flame streak badge
        ├── difficulty_badge.dart               # Difficulty pill
        ├── language_badge.dart                 # Language tag
        ├── stats_summary_card.dart             # Metrics row & today banner
        └── solution_card.dart                  # Problem card item

android/app/src/main/
├── kotlin/com/leetstreak/leetstreak/
│   ├── MainActivity.kt                         # MethodChannel & Intent routing
│   ├── SaveStreakTileService.kt                # Quick Settings TileService
│   └── StreakWidgetProvider.kt                 # Home Screen AppWidgetProvider
└── res/
    ├── layout/streak_widget_layout.xml         # RemoteViews widget UI
    ├── xml/streak_widget_info.xml              # AppWidget metadata
    └── drawable/                               # Vector icons & backgrounds
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
- Flutter SDK 3.44+
- Dart SDK 3.12+
- OpenJDK 17 or OpenJDK 21 (`brew install openjdk@21`)
- Android SDK (API 34/35/36)

### 1. Configure JDK for Flutter
```bash
flutter config --jdk-dir /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
```

### 2. Fetch Dependencies
```bash
flutter pub get
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Build Android Debug APK
```bash
flutter build apk --debug
```
The output APK is generated at:
`build/app/outputs/flutter-apk/app-debug.apk`

### 5. Install on Connected Device or Emulator
```bash
flutter run -d <device_id>
# or using adb:
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📱 How to Use Native Integrations

### Adding the Home Screen Widget
1. Long-press an empty space on your Android phone's home screen.
2. Tap **Widgets**.
3. Scroll to **LeetStreak** and drag the compact widget onto your home screen.
4. Tap the widget body anytime to view your dashboard, or tap **⚡ Save Streak** to jump straight into submitting a solution.

### Adding the Quick Settings Tile
1. Swipe down twice from the top of your screen to expand the Android Quick Settings panel.
2. Tap the **Edit / Pencil** icon to rearrange tiles.
3. Find **Save Streak** in the available tiles list and drag it into your active tiles.
4. Tap **Done**. Now you can tap "Save Streak" directly from your control panel anywhere on Android!

---

## 🔒 Security & Privacy Notice
LeetStreak operates entirely offline on your phone:
- Your saved solutions are stored in an encrypted/private SQLite database in your app's local sandbox.
- When logging into LeetCode within the submission WebView, your cookies stay exclusively in Android's native WebView storage.
- No user data, code, or tokens are ever uploaded to any third-party server.
