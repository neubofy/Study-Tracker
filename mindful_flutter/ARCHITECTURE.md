# Mindful App - Complete Architecture & Implementation Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Core Features](#core-features)
5. [Google Calendar Integration](#google-calendar-integration)
6. [Android Implementation](#android-implementation)
7. [Setup & Configuration](#setup--configuration)
8. [Testing](#testing)
9. [Deployment](#deployment)

---

## Project Overview

**Mindful** is a privacy-first, offline-first Flutter app that helps users regain control over their digital habits. Key characteristics:

- **Privacy-First**: No ads, no tracking, fully offline
- **Open Source**: GPL-2.0 license (or your choice)
- **Full-Featured**: Focus mode, screen time limits, notifications, bedtime mode, parental controls
- **Google Calendar Integration**: Auto-focus mode triggered by calendar events
- **Cross-Platform**: Built with Flutter for Android (extensible to iOS)

### Extra Feature: Google Calendar Auto-Focus

When enabled, the app:
1. Reads user's Google Calendar events (OAuth2)
2. Continuously monitors for active calendar events
3. Automatically enables Focus Mode (DND + app blocking) during events
4. Disables restrictions when events end
5. Keeps all data local - no server communication

---

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────┐
│        Flutter UI Layer                     │
│  (Screens, Navigation, State Management)   │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│     Service Layer                           │
│ • FocusModeManager                          │
│ • GoogleCalendarService                     │
│ • AndroidService (Platform Bridge)          │
│ • NotificationService                       │
│ • UsageStatsService                         │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│     Database Layer (Drift ORM)              │
│ • Focus Sessions                            │
│ • App Usage Limits                          │
│ • Calendar Events (Cached)                  │
│ • Usage Analytics                           │
│ • Settings & Configurations                 │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│     Android Native Layer                    │
│ • DND Control (NotificationManager)         │
│ • App Blocking                              │
│ • Usage Stats (UsageStatsManager)           │
│ • Local VPN Service                         │
│ • Biometric Auth                            │
│ • Foreground Service (Calendar Monitor)     │
└─────────────────────────────────────────────┘
```

---

## Project Structure

```
mindful_flutter/
├── lib/
│   ├── core/
│   │   ├── constants.dart          # App constants, durations, etc.
│   │   ├── enums.dart              # App-wide enums
│   │   └── extensions.dart         # Dart extensions
│   │
│   ├── database/
│   │   ├── schema.dart             # Drift table definitions
│   │   ├── app_database.dart       # Database instance & queries
│   │   └── migrations.dart         # Schema migrations
│   │
│   ├── services/
│   │   ├── google_calendar_service.dart    # Google OAuth + Calendar API
│   │   ├── focus_mode_manager.dart         # Focus Mode logic & state
│   │   ├── android_service.dart            # Platform channel bridge
│   │   ├── notification_service.dart       # Local notifications
│   │   ├── usage_stats_service.dart        # Screen time analytics
│   │   └── biometric_service.dart          # Biometric authentication
│   │
│   ├── features/
│   │   ├── focus_mode/
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   └── widgets/
│   │   ├── screen_time/
│   │   ├── notifications/
│   │   ├── bedtime_mode/
│   │   ├── parental_controls/
│   │   └── analytics/
│   │
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── focus_mode_screen.dart
│   │   │   ├── calendar_integration_screen.dart
│   │   │   ├── app_limits_screen.dart
│   │   │   ├── analytics_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── widgets/
│   │   │   ├── timer_widget.dart
│   │   │   ├── app_card.dart
│   │   │   └── chart_widgets.dart
│   │   └── navigation/
│   │       └── router.dart         # GoRouter configuration
│   │
│   ├── main.dart                   # App entry point
│   └── providers.dart              # Riverpod/Provider setup
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── kotlin/com/neubofy/mindful/
│   │       │   │   ├── MainActivity.kt
│   │       │   │   ├── services/
│   │       │   │   │   ├── CalendarMonitoringService.kt
│   │       │   │   │   └── LocalVpnService.kt
│   │       │   │   └── utils/
│   │       │   │       ├── DndHelper.kt
│   │       │   │       ├── AppBlockingHelper.kt
│   │       │   │       ├── VpnHelper.kt
│   │       │   │       ├── UsageStatsHelper.kt
│   │       │   │       └── BiometricHelper.kt
│   │       │   └── res/
│   │       │       ├── drawable/
│   │       │       └── values/
│   │
│   ├── gradle/
│   └── settings.gradle
│
├── test/
│   ├── unit_tests.dart
│   ├── widget_tests.dart
│   └── integration_tests.dart
│
├── pubspec.yaml
└── README.md
```

---

## Core Features

### 1. Focus Mode

**Files**: `focus_mode_manager.dart`, `focus_mode_screen.dart`

**Features**:
- Countdown & Stopwatch modes
- Session types: Study, Work, Creative, Break
- Automatic DND activation
- App blocking during focus
- Session logging & analytics
- Manual pause/resume/cancel

**State Management**:
```dart
class FocusModeManager extends ChangeNotifier {
  Future<void> startFocusSession({...}) // Start a focus session
  Future<void> pauseFocusSession() // Pause current session
  Future<void> resumeFocusSession() // Resume paused session
  Future<void> completeFocusSession() // End session normally
  Future<void> cancelFocusSession() // Abort session
  Future<void> startCalendarMonitoring() // Monitor for auto-focus
}
```

### 2. App Screen Time Limits

**Database**: `AppUsageLimits`, `AppGroups`, `AppBlockStatuses`

**Features**:
- Per-app daily time limits
- Shared limits for app groups
- Invincible Mode (tamper-proof blocking)
- Real-time usage tracking
- Automatic blocking when limit reached

**Query Functions**:
```dart
Future<AppUsageLimitData?> getAppLimit(String packageName)
Future<List<AppUsageLimitData>> getBlockedApps()
Future<void> updateAppUsedTime(String packageName, int addedSeconds)
```

### 3. Usage Analytics

**Database**: `DailyUsageRecords`

**Features**:
- Daily screen time tracking
- Per-app usage breakdown
- Weekly/monthly trends
- Data usage stats
- Historical analytics

### 4. Notification Management

**Database**: `NotificationRules`

**Features**:
- App-specific muting
- Batch notifications
- Schedule delivery times
- Allow/deny per-app

### 5. Bedtime Mode

**Database**: `BedtimeModes`

**Features**:
- Scheduled DND (e.g., 11 PM - 7 AM)
- App auto-pause
- Blacklist exclusions
- Automatic resumption

### 6. Parental Controls

**Database**: `ParentalControls`

**Features**:
- Biometric lock on restrictions
- Tamper-proof mode
- Max daily screen time
- App restrictions
- Admin override settings

### 7. Adult Content Filter

**Database**: `AdultContentFilters`

**Features**:
- DNS-based domain blocking
- App-level blocking
- Customizable blocklist
- Safe browsing

---

## Google Calendar Integration

### Architecture

```
┌─────────────────────────────────────────────┐
│   GoogleCalendarService                     │
│  (OAuth2, Event Fetching, Monitoring)      │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ↓                     ↓
   Google SignIn         Google Calendar API
   (googleapis)          (googleapis)
        │                     │
        └──────────┬──────────┘
                   ↓
    ┌─────────────────────────────────────┐
    │  Drift Database                     │
    │  • CalendarIntegrations             │
    │  • CachedCalendarEvents             │
    │  • CalendarSyncLogs                 │
    └─────────────────────────────────────┘
                   ↑
    ┌─────────────────────────────────────┐
    │  FocusModeManager                   │
    │  Auto-triggers on active events     │
    └─────────────────────────────────────┘
```

### Setup Steps

#### 1. Google Cloud Project Setup

```bash
# 1. Go to https://console.cloud.google.com/
# 2. Create a new project
# 3. Enable APIs:
#    - Google Calendar API
#    - Google Sign-In API
# 4. Create OAuth 2.0 credentials:
#    - Type: Web application
#    - Authorized redirect URIs: 
#      - http://localhost:8080
#      - com.neubofy.mindful://oauth
```

#### 2. Update AndroidManifest.xml

```xml
<application>
    <activity android:name=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="com.neubofy.mindful" android:host="oauth" />
        </intent-filter>
    </activity>
</application>
```

#### 3. Configure pubspec.yaml

```yaml
google_sign_in: ^6.2.0
googleapis: ^12.3.0
googleapis_auth: ^1.4.0
flutter_secure_storage: ^9.1.0
```

#### 4. Update GoogleCalendarService

```dart
class GoogleCalendarService {
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  
  // Implement sign-in, event fetching, sync monitoring
}
```

### Key Methods

```dart
// Sign in with Google
Future<bool> signIn() async { ... }

// Fetch calendar events for next N days
Future<List<CachedCalendarEventData>> fetchCalendarEvents({
  int daysAhead = 7
}) async { ... }

// Get currently active events
Future<List<CachedCalendarEventData>> getActiveEvents() async { ... }

// Get upcoming events
Future<List<CachedCalendarEventData>> getUpcomingEvents() async { ... }

// Start periodic sync every 5 minutes
void startPeriodicSync({
  Duration interval = const Duration(minutes: 5)
}) { ... }

// Sign out
Future<void> signOut() async { ... }
```

### Calendar Auto-Focus Flow

```
Timer.periodic(5 minutes)
  ↓
Check active calendar events
  ↓
  ├─ Event found → isActive = true
  │   ├─ Check if focus session running
  │   │   ├─ No → autoStartFromCalendarEvent()
  │   │   └─ Yes → continue monitoring
  │   └─ Track event-triggered sessions
  │
  └─ No events found → isActive = false
      ├─ Is current session calendar-triggered?
      │   ├─ Yes → completeFocusSession()
      │   └─ No → continue session
      └─ Events may have ended
```

### Secure Token Storage

```dart
// Tokens stored in FlutterSecureStorage (encrypted)
await _secureStorage.write(
  key: 'calendar_access_token',
  value: auth.accessToken,
);

await _secureStorage.write(
  key: 'calendar_refresh_token',
  value: auth.idToken,
);

// Retrieved when needed
final token = await _secureStorage.read(key: 'calendar_access_token');
```

---

## Android Implementation

### Native Services

#### 1. MainActivity.kt

Handles all platform method channels:
- DND control
- App blocking
- VPN management
- Usage stats
- Biometric auth
- Foreground service management

#### 2. CalendarMonitoringService.kt

- Runs as foreground service
- Minimizes battery drain
- Notifies Flutter layer of calendar events
- Implements notification persistence

#### 3. LocalVpnService.kt

- Provides local VPN tunnel
- Routes traffic for blocked apps
- Handles DNS filtering
- No internet connectivity impact

### Helper Classes

#### DndHelper.kt
```kotlin
fun enableDND(): Boolean
fun disableDND(): Boolean
```

#### AppBlockingHelper.kt
```kotlin
fun blockApp(packageName: String): Boolean
fun unblockApp(packageName: String): Boolean
fun enableBlocking(): Boolean
fun disableBlocking(): Boolean
fun isBlocked(packageName: String): Boolean
```

#### UsageStatsHelper.kt
```kotlin
fun getAppUsageStats(startDate: Long, endDate: Long): Map<String, Long>
fun getTodayScreenTime(): Long
fun getInstalledApps(): List<Map<String, Any>>
```

#### BiometricHelper.kt
```kotlin
fun isBiometricAvailable(): Boolean
fun authenticate(reason: String, callback: (Boolean) -> Unit)
```

#### VpnHelper.kt
```kotlin
fun blockInternet(packageName: String): Boolean
fun restoreInternet(packageName: String): Boolean
fun startVPN(): Boolean
fun stopVPN(): Boolean
```

### Permissions Required

```xml
<!-- Calendar Access -->
<uses-permission android:name="android.permission.READ_CALENDAR" />

<!-- Usage Access -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />

<!-- DND (Do Not Disturb) -->
<uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />

<!-- App Blocking & VPN -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.BIND_VPN_SERVICE" />

<!-- Biometric -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Background Services -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### Platform Channel Communication

**From Flutter**:
```dart
const platform = MethodChannel('com.neubofy.mindful/native');
final result = await platform.invokeMethod('enableDND');
```

**From Android**:
```kotlin
methodChannel.setMethodCallHandler { call, result ->
    when (call.method) {
        "enableDND" -> result.success(dndHelper.enableDND())
        "blockApp" -> {
            val packageName = call.argument<String>("packageName") ?: ""
            result.success(appBlockingHelper.blockApp(packageName))
        }
        // ... more methods
    }
}
```

---

## Setup & Configuration

### 1. Prerequisites

```bash
# Flutter SDK (3.13+)
flutter --version

# Android SDK (API 31+)
# Kotlin (1.8+)
# Gradle (8.0+)
```

### 2. Project Initialization

```bash
# Clone or create project
flutter create mindful

# Add dependencies
cd mindful
flutter pub get

# Generate code (Drift, Freezed, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Google OAuth Setup

```bash
# Download google-services.json from Firebase Console
# Place in: android/app/

# Update build.gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}

# Apply plugin in app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

### 4. Build APK

```bash
# Debug
flutter build apk

# Release
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

---

## Testing

### Unit Tests

```bash
# Run unit tests
flutter test test/unit_tests.dart

# Run all tests
flutter test

# Coverage
flutter test --coverage
```

### Test Scenarios

#### Focus Mode Tests
✅ Start/pause/resume/cancel sessions
✅ Timer accuracy
✅ DND state synchronization
✅ App blocking activation
✅ Session persistence

#### Calendar Integration Tests
✅ OAuth sign-in/sign-out
✅ Event fetching
✅ Auto-focus triggering
✅ Event end detection
✅ Token refresh

#### App Blocking Tests
✅ Block/unblock individual apps
✅ Group limit enforcement
✅ Invincible mode tamper-proof
✅ Usage stats accuracy
✅ VPN routing

#### Android Native Tests
✅ DND permission checks
✅ Usage stats access
✅ Biometric availability
✅ Service lifecycle

---

## Deployment

### Pre-Release Checklist

- [ ] Test all features on Android 12+
- [ ] Verify permissions requested
- [ ] Test calendar sync with multiple events
- [ ] Verify biometric auth flow
- [ ] Test with poor network connectivity
- [ ] Battery drain tests (foreground service)
- [ ] Verify offline functionality
- [ ] Check database migrations
- [ ] Security audit of OAuth tokens
- [ ] Privacy policy updated

### Play Store Submission

1. **Update version** in `pubspec.yaml`
2. **Create release APK**:
   ```bash
   flutter build apk --release
   ```
3. **Or create App Bundle** (recommended):
   ```bash
   flutter build appbundle --release
   ```
4. **Sign the bundle**:
   ```bash
   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
     -keystore ~/keystore.jks \
     build/app/outputs/bundle/release/app-release.aab \
     alias_name
   ```
5. **Upload to Play Store Console**

### GitHub Release

```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# Create GitHub Release with APK
```

---

## Bonus: UX Improvements vs. Original Mindful

### 1. **Streamlined Onboarding**
- Skip/customize initial setup
- Smart defaults based on device usage patterns
- Progressive permission requests
- Interactive tour for calendar integration

### 2. **Enhanced Calendar Integration**
- One-tap Google Calendar sync
- Visual calendar event preview
- Automatic Focus Mode without manual setup
- Event-specific focus notes

### 3. **Improved Analytics Dashboard**
- Weekly/monthly trends with charts
- Productivity insights ("Best focus time: Tuesday 10AM")
- App usage breakdown with pie charts
- Recommended app limits

### 4. **Smart Notifications**
- Batch mode shows only important notifications
- Scheduled delivery (not during focus)
- Smart grouping by app category
- Tappable quick-actions

### 5. **Parental Controls Enhancement**
- Biometric-protected settings
- Activity reports with trends
- Scheduled screen time (school hours)
- Reward system integration

### 6. **Dark Mode & Themes**
- Full dark mode support
- Custom color themes
- Font size preferences
- High contrast mode for accessibility

### 7. **Offline-First Architecture**
- Full offline functionality
- Automatic sync when online
- Conflict resolution for calendar
- Local backup/restore

---

## Key Takeaways for Implementation

### Critical Implementation Points

1. **Google Calendar Sync** (`GoogleCalendarService`)
   - Use OAuth2 with secure token storage
   - Periodic polling every 5 minutes
   - Cache events locally with expiry
   - Handle token refresh gracefully

2. **Focus Mode Automation** (`FocusModeManager`)
   - Monitor active calendar events continuously
   - Auto-trigger on event start
   - Auto-complete on event end
   - Allow manual override

3. **Android Native Bridge** (`MainActivity.kt`)
   - Implement all platform methods
   - Handle permission checks
   - Manage foreground service lifecycle
   - Log errors for debugging

4. **Database Queries** (`app_database.dart`)
   - Implement all necessary queries in one place
   - Use Drift's type-safe API
   - Handle migrations properly
   - Test queries with sample data

5. **Testing Strategy**
   - Unit test all business logic
   - Mock Android services
   - Integration test calendar flow
   - Test with real calendar events

---

## Additional Resources

- Flutter Docs: https://flutter.dev/docs
- Drift ORM: https://drift.simonbinder.eu/
- Google Calendar API: https://developers.google.com/calendar
- Android Development: https://developer.android.com/docs

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-18  
**Status**: Ready for Implementation
