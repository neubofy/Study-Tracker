# Mindful App - Implementation Roadmap & Quick Start Guide

## Quick Start (30 Minutes)

### Step 1: Project Setup
```bash
# Clone existing project
cd mindful_flutter

# Get dependencies
flutter pub get

# Generate code (Drift, Freezed, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Configure Google Cloud
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project: "Mindful App"
3. Enable APIs:
   - Google Calendar API
   - Google Sign-In API
4. Create OAuth 2.0 Web Application credentials
5. Add authorized redirect URIs:
   ```
   http://localhost:8080
   com.neubofy.mindful://oauth
   ```
6. Download `client_id` and `client_secret`

### Step 3: Update Google Calendar Service
```dart
// lib/services/google_calendar_service.dart
class GoogleCalendarService {
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  // ... rest of implementation
}
```

### Step 4: Run the App
```bash
# Build and run on Android
flutter run

# Or with specific device
flutter run -d emulator-5554
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1)
**Goal**: Database, models, and basic services

Tasks:
- [x] Create Drift database schema
- [x] Implement AppDatabase with queries
- [x] Set up Android service bridge (MainActivity.kt)
- [x] Create Android helper classes (DND, App Blocking, etc.)
- [x] Implement AndroidService (Dart) platform channel

**Deliverables**:
- Working database with full CRUD operations
- Android native services responding to method calls
- Test: `flutter test` should pass database tests

**Time**: 3-4 days

---

### Phase 2: Google Calendar Integration (Week 2)
**Goal**: OAuth2 sign-in and calendar event synchronization

Tasks:
- [ ] Implement GoogleCalendarService
  - [ ] Sign-in/sign-out logic
  - [ ] Token storage (FlutterSecureStorage)
  - [ ] Calendar event fetching
  - [ ] Periodic sync (5 minutes)
- [ ] Create CalendarIntegrationScreen UI
- [ ] Add to home navigation

**Key Files to Complete**:
- `lib/services/google_calendar_service.dart` (core logic)
- `lib/ui/screens/calendar_integration_screen.dart` (UI)
- `android/app/src/main/AndroidManifest.xml` (permissions & redirect URI)

**Test Scenarios**:
```dart
// Test sign-in
await calendarService.signIn();

// Test event fetching
final events = await calendarService.fetchCalendarEvents();
expect(events.isNotEmpty, true);

// Test periodic sync
calendarService.startPeriodicSync();
```

**Time**: 4-5 days

---

### Phase 3: Focus Mode & Auto-Focus (Week 2-3)
**Goal**: Manual focus sessions + automatic triggering from calendar

Tasks:
- [x] Create FocusModeManager with state management
- [x] Implement focus session lifecycle (start, pause, resume, complete, cancel)
- [x] Create FocusModeScreen UI
- [x] Integrate DND and app blocking
- [ ] Add calendar monitoring to FocusModeManager
- [ ] Test auto-triggering on calendar events

**Auto-Focus Flow**:
```dart
// Monitor calendar for active events
Future<void> startCalendarMonitoring() async {
  Timer.periodic(Duration(seconds: 30), (_) async {
    final activeEvents = await calendarService.getActiveEvents();
    
    if (activeEvents.isNotEmpty && !isActive) {
      // Auto-start focus mode
      await autoStartFromCalendarEvent(activeEvents.first);
    }
    
    if (isActive && currentSession!.isCalendarTriggered && activeEvents.isEmpty) {
      // Auto-complete when event ends
      await completeFocusSession();
    }
  });
}
```

**UI Implementation**:
- Timer display (countdown/stopwatch)
- Start/Pause/Resume/Complete buttons
- Session type selector
- Duration options

**Time**: 3-4 days

---

### Phase 4: App Screen Time Limits (Week 3-4)
**Goal**: Track, limit, and enforce app usage

Tasks:
- [ ] Implement AppLimitsScreen
- [ ] Create app blocking triggers
- [ ] Set up usage stats polling
- [ ] Add Invincible Mode
- [ ] Group app limits

**Core Logic**:
```dart
// Check usage and enforce limits
Future<void> enforceAppLimits() async {
  final limits = await db.getAllAppLimits();
  
  for (final limit in limits) {
    if (limit.usedTimeToday >= limit.dailyLimitInMinutes * 60) {
      await androidService.blockApp(limit.packageName);
      
      if (limit.isInvincibleMode) {
        // Can't be unblocked without biometric
        await biometricService.authenticate(...);
      }
    }
  }
}
```

**Time**: 3-4 days

---

### Phase 5: Notifications & Bedtime Mode (Week 4)
**Goal**: Smart notifications and auto-pause at night

Tasks:
- [ ] Implement NotificationService
- [ ] Create notification rules engine
- [ ] Build BedtimeModeScreen
- [ ] Add scheduled DND and app pause

**Features**:
- Batch notifications (group by app)
- Scheduled delivery
- Time-based muting
- Bedtime window with app pause

**Time**: 2-3 days

---

### Phase 6: Analytics & Parental Controls (Week 5)
**Goal**: Usage insights and family safety

Tasks:
- [ ] Create AnalyticsScreen with charts
- [ ] Implement ParentalControlsScreen
- [ ] Add biometric lock for settings
- [ ] Build activity reports

**Insights to Show**:
- Daily/weekly screen time trends
- Top apps by usage
- Focus time achievements
- Productivity scores

**Time**: 3-4 days

---

### Phase 7: Polish & Testing (Week 5-6)
**Goal**: Complete implementation and prepare for release

Tasks:
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Battery drain analysis
- [ ] UI/UX refinements
- [ ] Documentation updates
- [ ] Test on multiple Android versions

**Testing Checklist**:
- [ ] Focus mode timer accuracy (±1 second)
- [ ] Calendar sync reliability
- [ ] App blocking enforcement
- [ ] Biometric authentication
- [ ] Database queries performance
- [ ] Battery consumption (<5% with monitoring)
- [ ] Permission handling
- [ ] Offline functionality

**Time**: 2-3 days

---

## Key Implementation Details

### 1. Database Queries Pattern

All queries should be added to `AppDatabase`:

```dart
class AppDatabase extends _$AppDatabase {
  // Query: Get active focus session
  Future<FocusSessionData?> getActiveFocusSession() {
    return (select(focusSessions)
          ..where((tbl) => tbl.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
  }

  // Mutation: Insert or update app limit
  Future<void> insertOrUpdateAppLimit(AppUsageLimitsCompanion limit) {
    return into(appUsageLimits).insertOnConflictUpdate(limit);
  }
}
```

### 2. Platform Channel Pattern

**Dart to Android**:
```dart
final result = await platform.invokeMethod<bool>('enableDND');
```

**Android to Dart** (in MainActivity.kt):
```kotlin
methodChannel.setMethodCallHandler { call, result ->
    when (call.method) {
        "enableDND" -> result.success(dndHelper.enableDND())
        else -> result.notImplemented()
    }
}
```

### 3. Service Lifecycle

```dart
// In main.dart
void main() async {
  // 1. Initialize services
  final calendarService = GoogleCalendarService(db);
  await calendarService.initialize();
  
  // 2. Request permissions
  await requestPermissions();
  
  // 3. Start monitoring
  await focusManager.startCalendarMonitoring();
  
  // 4. Start usage stats
  await usageStatsService.startUsageMonitoring();
  
  // In dispose
  // 5. Clean up
  calendarService.stopPeriodicSync();
  usageStatsService.stopUsageMonitoring();
}
```

### 4. State Management Pattern

Using Provider + ChangeNotifier:

```dart
// In providers setup
ChangeNotifierProvider(
  create: (_) => FocusModeManager(db, androidService, calendarService),
),

// In UI
Consumer<FocusModeManager>(
  builder: (context, focusManager, _) {
    if (focusManager.isActive) {
      return _buildActiveFocusUI(focusManager);
    }
    return _buildSetupUI(focusManager);
  },
)
```

---

## Common Implementation Pitfalls

### ❌ Pitfall 1: Not handling token refresh
**Problem**: Google OAuth token expires after 1 hour
**Solution**: Implement automatic token refresh in GoogleCalendarService

```dart
Future<void> _refreshTokenIfNeeded() async {
  if (DateTime.now().isAfter(_tokenExpiryTime)) {
    // Request new token using refresh token
    await _calendarApi?.events.list('primary');
  }
}
```

### ❌ Pitfall 2: Blocking main thread with sync calls
**Problem**: Android calls take time (usage stats, calendar sync)
**Solution**: Always use async/await and run on background thread

```dart
// ✅ Good
final stats = await _androidService.getAppUsageStats(...);

// ❌ Bad
final stats = _androidService.getAppUsageStats(...); // No await
```

### ❌ Pitfall 3: Not cleaning up timers
**Problem**: Memory leaks and battery drain
**Solution**: Always cancel timers in dispose()

```dart
@override
void dispose() {
  _focusTimer?.cancel();
  _usageCheckTimer?.cancel();
  _syncTimer?.cancel();
  super.dispose();
}
```

### ❌ Pitfall 4: Assuming calendar events are same day
**Problem**: Events can span midnight
**Solution**: Always check both date and time

```dart
// ✅ Good
final isActive = event.startTime.isBefore(now) && 
                 event.endTime.isAfter(now);

// ❌ Bad
if (event.date == today) { ... }
```

### ❌ Pitfall 5: Not testing permission denial
**Problem**: App crashes if user denies calendar permission
**Solution**: Always check permissions before using feature

```dart
if (!await _hasCalendarPermission()) {
  _showPermissionDialog();
  return;
}
```

---

## Testing Strategy

### Unit Tests
```bash
flutter test test/unit_tests.dart
```

Focus areas:
- Focus mode state machine
- Calendar event logic
- Database queries
- Time calculations

### Widget Tests
```bash
flutter test test/widget_tests.dart
```

Focus areas:
- UI state updates
- Button interactions
- Navigation
- Form validation

### Integration Tests
```bash
flutter test test/integration_tests.dart
```

Focus areas:
- Full focus mode workflow
- Calendar sign-in and sync
- App blocking enforcement
- End-to-end scenarios

---

## Performance Targets

| Metric | Target | How to Measure |
|--------|--------|----------------|
| App Launch | < 2 seconds | `flutter run --profile` |
| Calendar Sync | < 5 seconds | Log timestamps |
| Focus Mode Timer | ±1 second accuracy | Compare with system clock |
| Battery Drain (idle) | < 1% per hour | Device battery settings |
| Database Query | < 50ms | `dartlog` traces |
| Memory Usage | < 150MB | Android Monitor |

---

## Deployment Checklist

Before Play Store release:

- [ ] All features implemented
- [ ] All tests passing
- [ ] No debug prints in production code
- [ ] Version bumped (pubspec.yaml)
- [ ] Privacy policy updated
- [ ] Privacy Policy link in app description
- [ ] Tested on Android 12, 13, 14
- [ ] Tested with multiple calendar accounts
- [ ] Tested with poor network (offline works)
- [ ] All permissions explained
- [ ] Release APK signed
- [ ] Screenshots ready (play store)
- [ ] App description written
- [ ] Contact info in app
- [ ] Source code documented

---

## Next Steps

1. **Week 1**: Start with Phase 1 (Database + Android setup)
2. **Week 2**: Complete Phase 2 (Google Calendar) and start Phase 3
3. **Week 3-4**: Complete remaining features
4. **Week 5-6**: Testing and polish
5. **Week 7**: Prepare for Play Store release

---

## Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Drift Documentation**: https://drift.simonbinder.eu/
- **Google Calendar API**: https://developers.google.com/calendar/api/
- **Android Development**: https://developer.android.com/
- **Play Store Guidelines**: https://play.google.com/console

---

## Support & Questions

For issues during implementation:
1. Check the ARCHITECTURE.md for detailed info
2. Review test files for usage examples
3. Check platform channels for native issues
4. Debug with `flutter logs`
5. Use Android Studio for native debugging

---

**Last Updated**: 2025-11-18  
**Version**: 1.0.0  
**Status**: Ready for Implementation
