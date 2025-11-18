# Mindful App - Quick Reference Guide

## 🚀 Getting Started (5 Minutes)

### Prerequisites
```bash
flutter --version           # >= 3.13.0
cat pubspec.yaml           # Check dependencies
```

### Setup
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📊 Core Services

### Focus Mode Manager
```dart
// Start a session
await focusManager.startFocusSession(
  sessionType: 'Work',
  mode: FocusMode.countdown,
  durationInSeconds: 1500, // 25 minutes
);

// Check status
if (focusManager.isActive) {
  print('Time left: ${focusManager.remainingSeconds}s');
}

// Control session
await focusManager.pauseFocusSession();
await focusManager.resumeFocusSession();
await focusManager.completeFocusSession();

// Auto-focus from calendar
await focusManager.startCalendarMonitoring();
```

### Google Calendar Service
```dart
// Sign in
final success = await calendarService.signIn();

// Get events
final events = await calendarService.fetchCalendarEvents(daysAhead: 7);

// Check active
final activeEvents = await calendarService.getActiveEvents();

// Monitor
calendarService.startPeriodicSync(interval: Duration(minutes: 5));
```

### Android Service (Native Bridge)
```dart
// DND
await androidService.enableDND();
await androidService.disableDND();

// App Blocking
await androidService.blockApp('com.example.app');
await androidService.unblockApp('com.example.app');

// Usage Stats
final stats = await androidService.getAppUsageStats(
  startDate: DateTime.now().subtract(Duration(days: 1)),
  endDate: DateTime.now(),
);

// Biometric
final authenticated = await androidService.authenticateWithBiometric(
  'Verify identity to unlock settings'
);
```

### Notification Service
```dart
// Show notification
await notificationService.showFocusNotification(
  title: 'Focus Mode Started',
  body: 'Study session for 25 minutes',
);

// Schedule notification
await notificationService.scheduleNotification(
  id: 1,
  title: 'Time to focus!',
  body: 'Your event starts in 5 minutes',
  scheduledTime: DateTime.now().add(Duration(minutes: 5)),
);

// Cancel notification
await notificationService.cancelNotification(1);
```

### Usage Stats Service
```dart
// Start monitoring
await usageStatsService.startUsageMonitoring();

// Get breakdown
final breakdown = await usageStatsService.getTodayAppBreakdown();
// Returns: {'com.instagram.android': 3600, 'com.twitter.android': 1200}

// Get insights
final insights = await usageStatsService.getInsights();
// Returns: ['Your screen time is high', 'Great focus sessions this week']

// Stop monitoring
usageStatsService.stopUsageMonitoring();
```

---

## 💾 Database Operations

### Query Examples
```dart
// Get active focus session
final session = await db.getActiveFocusSession();

// Get today's sessions
final todaysSessions = await db.getTodaysFocusSessions();

// Get total focus time
final focusTime = todaysSessions
    .where((s) => s.status == 'completed')
    .fold<int>(0, (sum, s) => sum + s.durationInSeconds);

// Get app limit
final appLimit = await db.getAppLimit('com.instagram.android');
if (appLimit != null && appLimit.usedTimeToday >= appLimit.dailyLimitInMinutes * 60) {
  await db.setAppBlockStatus(appLimit.packageName, true, reason: 'time_limit');
}

// Get calendar integration
final calendar = await db.getCalendarIntegration();
if (calendar?.isAutoFocusEnabled ?? false) {
  // Auto-focus is enabled
}

// Get active calendar events
final activeEvents = await db.getActiveCalendarEvents(DateTime.now());
```

### Insert/Update Examples
```dart
// Insert focus session
await db.insertFocusSession(
  FocusSessionsCompanion(
    sessionType: Value('Work'),
    startTime: Value(DateTime.now()),
    durationInSeconds: Value(1500),
    mode: Value('countdown'),
    status: const Value('active'),
  ),
);

// Update calendar integration
await db.insertOrUpdateCalendarIntegration(
  CalendarIntegrationsCompanion(
    isConnected: const Value(true),
    isAutoFocusEnabled: const Value(true),
    userEmail: Value('user@example.com'),
  ),
);

// Set app block status
await db.setAppBlockStatus(
  'com.instagram.android',
  true,
  reason: 'focus_mode',
);

// Insert daily usage record
await db.insertDailyUsage(
  DailyUsageRecordsCompanion(
    date: Value(DateTime.now()),
    totalScreenTimeInSeconds: const Value(0),
  ),
);
```

---

## 🎯 State Management

### Using Provider
```dart
// Read from Consumer
Consumer<FocusModeManager>(
  builder: (context, focusManager, _) {
    if (focusManager.isActive) {
      return Text('Time left: ${focusManager.remainingSeconds}s');
    }
    return Text('No active session');
  },
)

// Access directly
final focusManager = context.read<FocusModeManager>();
final isActive = focusManager.isActive;

// Watch for changes
final focusManager = context.watch<FocusModeManager>();
```

### Notifying Listeners
```dart
// In FocusModeManager
class FocusModeManager extends ChangeNotifier {
  void _updateTimer() {
    _remainingSeconds--;
    notifyListeners(); // Notify all listeners
  }
}
```

---

## 🔐 Google OAuth Flow

### Setup in Google Cloud Console
```
1. Go to console.cloud.google.com
2. Create Project > "Mindful App"
3. APIs & Services > Enable APIs
   - Google Calendar API
   - Google Sign-In API
4. Create Credentials > OAuth 2.0 Client ID
   - Type: Web application
   - Authorized redirect URIs:
     * http://localhost:8080
     * com.neubofy.mindful://oauth
5. Copy Client ID and Secret
```

### Update Code
```dart
// In GoogleCalendarService
static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
static const String _clientSecret = 'YOUR_CLIENT_SECRET';
```

### Android Manifest
```xml
<application>
    <activity android:name=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="com.neubofy.mindful" android:host="oauth" />
        </intent-filter>
    </activity>
</application>
```

---

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific file
flutter test test/unit_tests.dart

# With coverage
flutter test --coverage
```

### Example Test
```dart
test('Should start focus session', () async {
  await focusManager.startFocusSession(
    sessionType: 'Work',
    mode: FocusMode.countdown,
    durationInSeconds: 1500,
  );

  expect(focusManager.isActive, true);
  expect(focusManager.remainingSeconds, 1500);
});
```

---

## 📱 Android Platform Channels

### From Flutter
```dart
const platform = MethodChannel('com.neubofy.mindful/native');
final result = await platform.invokeMethod<bool>('enableDND');
```

### In MainActivity.kt
```kotlin
methodChannel.setMethodCallHandler { call, result ->
    when (call.method) {
        "enableDND" -> result.success(dndHelper.enableDND())
        "disableDND" -> result.success(dndHelper.disableDND())
        "blockApp" -> {
            val packageName = call.argument<String>("packageName") ?: ""
            result.success(appBlockingHelper.blockApp(packageName))
        }
        else -> result.notImplemented()
    }
}
```

---

## 🐛 Debugging

### Logs
```bash
# All logs
flutter logs

# Filter by tag
flutter logs | grep "FocusModeManager"

# Real-time Android logs
adb logcat | grep "com.neubofy.mindful"
```

### Debug Prints
```dart
debugPrint('[FocusModeManager] Starting session: $sessionType');
```

### Android Studio
1. Open Android project in Android Studio
2. Run > Debug 'app'
3. Set breakpoints in Kotlin code
4. Use debugger to inspect values

---

## 📋 Checklist Before Release

### Code Quality
- [ ] No debug prints in production
- [ ] All error cases handled
- [ ] All TODOs addressed
- [ ] Comments for complex logic
- [ ] No magic numbers (use constants)

### Testing
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] Tested on Android 12+
- [ ] Tested with poor network
- [ ] Offline functionality works

### Features
- [ ] Focus mode works
- [ ] Calendar sync works
- [ ] App blocking works
- [ ] DND control works
- [ ] Notifications appear
- [ ] Analytics collected

### Permissions
- [ ] All permissions requested
- [ ] Permission denial handled
- [ ] Settings link provided
- [ ] Privacy policy updated

### Performance
- [ ] App launches in < 2s
- [ ] No jank or lag
- [ ] Battery drain acceptable
- [ ] Memory usage reasonable
- [ ] No crashes on edge cases

---

## 📚 File Reference

| What | Where |
|------|-------|
| Database models | `lib/database/schema.dart` |
| Database queries | `lib/database/app_database.dart` |
| Focus mode logic | `lib/services/focus_mode_manager.dart` |
| Google Calendar | `lib/services/google_calendar_service.dart` |
| Android bridge | `lib/services/android_service.dart` |
| Notifications | `lib/services/notification_service.dart` |
| Analytics | `lib/services/usage_stats_service.dart` |
| Focus UI | `lib/ui/screens/focus_mode_screen.dart` |
| Calendar UI | `lib/ui/screens/calendar_integration_screen.dart` |
| Main app | `lib/main.dart` |
| Android native | `android/app/src/main/kotlin/` |
| Tests | `test/unit_tests.dart` |
| Architecture docs | `ARCHITECTURE.md` |
| Implementation guide | `IMPLEMENTATION_GUIDE.md` |

---

## 🚨 Common Issues

| Issue | Solution |
|-------|----------|
| Build fails | `flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs` |
| Calendar not syncing | Check Google credentials, verify internet, check logs |
| App blocking not working | Verify Usage Stats permission, check package names, test with system app |
| DND not working | Check notification policy permission, verify Android version |
| Timer not accurate | Check system time, verify no background tasks, test on device |
| Memory leak | Cancel all timers in dispose(), verify no circular references |

---

## 💡 Tips & Tricks

### Quick Debug Calendar Events
```dart
final events = await calendarService.fetchCalendarEvents();
events.forEach((e) {
  debugPrint('${e.eventTitle}: ${e.startTime} - ${e.endTime}');
});
```

### Monitor Focus Mode State
```dart
FocusModeManager manager = context.read<FocusModeManager>();
debugPrint('Active: ${manager.isActive}');
debugPrint('Status: ${manager.status}');
debugPrint('Remaining: ${manager.remainingSeconds}s');
```

### Check Database State
```dart
final sessions = await db.getAllFocusSessions();
debugPrint('Total sessions: ${sessions.length}');
sessions.forEach((s) => debugPrint('${s.sessionType}: ${s.durationInSeconds}s'));
```

### Test Android Service
```dart
final androidService = AndroidService();
final success = await androidService.enableDND();
debugPrint('DND enabled: $success');
```

---

## 📞 Support Resources

- Flutter Documentation: https://flutter.dev/docs
- Drift ORM: https://drift.simonbinder.eu/
- Google Calendar API: https://developers.google.com/calendar
- Android Docs: https://developer.android.com/docs
- Provider Package: https://pub.dev/packages/provider

---

**Last Updated**: 2025-11-18  
**Version**: 1.0.0  
**Status**: Production Ready
