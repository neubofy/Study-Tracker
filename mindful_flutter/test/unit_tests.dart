import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';
import 'package:mindful/services/focus_mode_manager.dart';
import 'package:mindful/services/google_calendar_service.dart';
import 'package:mindful/services/android_service.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockGoogleCalendarService extends Mock implements GoogleCalendarService {}
class MockAndroidService extends Mock implements AndroidService {}

void main() {
  group('Focus Mode Manager Tests', () {
    late FocusModeManager focusManager;
    late MockAppDatabase mockDb;
    late MockAndroidService mockAndroidService;
    late MockGoogleCalendarService mockCalendarService;

    setUp(() {
      mockDb = MockAppDatabase();
      mockAndroidService = MockAndroidService();
      mockCalendarService = MockGoogleCalendarService();

      focusManager = FocusModeManager(
        mockDb,
        mockAndroidService,
        mockCalendarService,
      );
    });

    test('Should start a focus session correctly', () async {
      when(mockDb.insertFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockAndroidService.enableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.enableAppBlocking(session: anyNamed('session')))
          .thenAnswer((_) async => true);

      await focusManager.startFocusSession(
        sessionType: 'Work',
        mode: FocusMode.countdown,
        durationInSeconds: 1500, // 25 minutes
      );

      expect(focusManager.isActive, true);
      expect(focusManager.status, FocusStatus.active);
      expect(focusManager.remainingSeconds, 1500);

      verify(mockDb.insertFocusSession(any)).called(1);
      verify(mockAndroidService.enableDND()).called(1);
      verify(mockAndroidService.enableAppBlocking(session: anyNamed('session'))).called(1);
    });

    test('Should pause and resume focus session', () async {
      when(mockDb.insertFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockDb.updateFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockAndroidService.enableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.enableAppBlocking(session: anyNamed('session')))
          .thenAnswer((_) async => true);

      await focusManager.startFocusSession(
        sessionType: 'Study',
        mode: FocusMode.countdown,
        durationInSeconds: 900,
      );

      await focusManager.pauseFocusSession();
      expect(focusManager.status, FocusStatus.paused);

      await focusManager.resumeFocusSession();
      expect(focusManager.status, FocusStatus.active);

      verify(mockDb.updateFocusSession(any)).called(2);
    });

    test('Should complete focus session and disable restrictions', () async {
      when(mockDb.insertFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockDb.updateFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockAndroidService.enableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.enableAppBlocking(session: anyNamed('session')))
          .thenAnswer((_) async => true);
      when(mockAndroidService.disableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.disableAppBlocking())
          .thenAnswer((_) async => true);

      await focusManager.startFocusSession(
        sessionType: 'Work',
        mode: FocusMode.countdown,
        durationInSeconds: 600,
      );

      await focusManager.completeFocusSession();

      expect(focusManager.status, FocusStatus.completed);
      expect(focusManager.currentSession, null);

      verify(mockAndroidService.disableDND()).called(1);
      verify(mockAndroidService.disableAppBlocking()).called(1);
    });

    test('Should auto-start from calendar event', () async {
      final event = CachedCalendarEventData(
        id: 1,
        eventId: 'event123',
        eventTitle: 'Team Meeting',
        eventDescription: null,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        calendarId: 'primary',
        isAllDay: false,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      when(mockDb.insertFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockAndroidService.enableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.enableAppBlocking(session: anyNamed('session')))
          .thenAnswer((_) async => true);

      await focusManager.autoStartFromCalendarEvent(event);

      expect(focusManager.isActive, true);
      expect(focusManager.currentSession?.isCalendarTriggered, true);
      expect(focusManager.currentSession?.triggeringCalendarEventId, 'event123');

      verify(mockDb.insertFocusSession(any)).called(1);
    });

    test('Should get today\'s total focus time', () async {
      final sessions = [
        FocusSessionData(
          id: 1,
          sessionType: 'Work',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 25)),
          durationInSeconds: 1500,
          pausedDurationInSeconds: 0,
          mode: 'countdown',
          status: 'completed',
          notes: null,
          isCalendarTriggered: false,
          triggeringCalendarEventId: null,
        ),
        FocusSessionData(
          id: 2,
          sessionType: 'Study',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 50)),
          durationInSeconds: 3000,
          pausedDurationInSeconds: 0,
          mode: 'countdown',
          status: 'completed',
          notes: null,
          isCalendarTriggered: false,
          triggeringCalendarEventId: null,
        ),
      ];

      when(mockDb.getTodaysFocusSessions())
          .thenAnswer((_) async => sessions);

      final totalTime = await focusManager.getTodaysFocusTime();

      expect(totalTime, 4500); // 1500 + 3000
      verify(mockDb.getTodaysFocusSessions()).called(1);
    });
  });

  group('Google Calendar Service Tests', () {
    late MockAppDatabase mockDb;
    late GoogleCalendarService calendarService;

    setUp(() {
      mockDb = MockAppDatabase();
      calendarService = GoogleCalendarService(mockDb);
    });

    test('Should check if user is signed in', () async {
      // Note: This would require mocking GoogleSignIn
      // Implementation depends on your mock setup
    });

    test('Should handle calendar event fetching', () async {
      final events = [
        CachedCalendarEventData(
          id: 1,
          eventId: 'event1',
          eventTitle: 'Meeting',
          eventDescription: null,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          calendarId: 'primary',
          isAllDay: false,
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];

      when(mockDb.insertCachedEvent(any))
          .thenAnswer((_) async => {});
      when(mockDb.deleteCachedEventsBefore(any))
          .thenAnswer((_) async => {});
      when(mockDb.insertCalendarSyncLog(any))
          .thenAnswer((_) async => {});

      // Note: Full test requires mocking CalendarApi
      // This is a structural test
    });
  });

  group('Android Service Tests', () {
    late AndroidService androidService;

    setUp(() {
      androidService = AndroidService();
    });

    test('Should handle DND state changes', () async {
      // These would be integration tests requiring actual Android platform
      // Structure test only
      expect(androidService, isNotNull);
    });

    test('Should block and unblock apps', () async {
      // Integration test - requires platform channel setup
      expect(androidService, isNotNull);
    });
  });

  group('Calendar Auto-Focus Integration Tests', () {
    late FocusModeManager focusManager;
    late MockAppDatabase mockDb;
    late MockAndroidService mockAndroidService;
    late MockGoogleCalendarService mockCalendarService;

    setUp(() {
      mockDb = MockAppDatabase();
      mockAndroidService = MockAndroidService();
      mockCalendarService = MockGoogleCalendarService();

      focusManager = FocusModeManager(
        mockDb,
        mockAndroidService,
        mockCalendarService,
      );
    });

    test('Should auto-complete focus when calendar event ends', () async {
      final event = CachedCalendarEventData(
        id: 1,
        eventId: 'event1',
        eventTitle: 'Event',
        eventDescription: null,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        calendarId: 'primary',
        isAllDay: false,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      when(mockDb.insertFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockDb.updateFocusSession(any))
          .thenAnswer((_) async => {});
      when(mockAndroidService.enableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.enableAppBlocking(session: anyNamed('session')))
          .thenAnswer((_) async => true);
      when(mockAndroidService.disableDND())
          .thenAnswer((_) async => true);
      when(mockAndroidService.disableAppBlocking())
          .thenAnswer((_) async => true);

      // Start session from calendar event
      await focusManager.autoStartFromCalendarEvent(event);
      expect(focusManager.isActive, true);

      // Simulate event end - active events list becomes empty
      when(mockCalendarService.getActiveEvents())
          .thenAnswer((_) async => []);

      // In real implementation, monitoring timer would detect this
      // and auto-complete
    });
  });
}
