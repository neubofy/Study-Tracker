import 'package:flutter/foundation.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';
import 'package:mindful/services/google_calendar_service.dart';
import 'package:mindful/services/android_service.dart';
import 'dart:async';

enum FocusMode { countdown, stopwatch }
enum FocusStatus { active, paused, completed, cancelled }

class FocusModeManager extends ChangeNotifier {
  final AppDatabase _db;
  final AndroidService _androidService;
  final GoogleCalendarService _calendarService;

  Timer? _focusTimer;
  FocusSessionData? _currentSession;

  int _remainingSeconds = 0;
  FocusStatus _status = FocusStatus.completed;

  // Getters
  FocusSessionData? get currentSession => _currentSession;
  int get remainingSeconds => _remainingSeconds;
  FocusStatus get status => _status;
  bool get isActive => _currentSession != null && _status == FocusStatus.active;

  FocusModeManager(
    this._db,
    this._androidService,
    this._calendarService,
  ) {
    _initializeCurrentSession();
  }

  /// Initialize session from database (on app start)
  Future<void> _initializeCurrentSession() async {
    _currentSession = await _db.getActiveFocusSession();
    if (_currentSession != null) {
      _status = FocusStatus.values.firstWhere(
        (s) => s.name == _currentSession!.status,
        orElse: () => FocusStatus.completed,
      );
      
      if (_status == FocusStatus.active) {
        _remainingSeconds = _calculateRemainingSeconds(_currentSession!);
        _startFocusTimer();
      }
    }
    notifyListeners();
  }

  /// Start a focus session (manual or calendar-triggered)
  Future<void> startFocusSession({
    required String sessionType,
    required FocusMode mode,
    required int durationInSeconds,
    String? triggeringCalendarEventId,
  }) async {
    try {
      // Cancel any existing session
      if (_currentSession != null) {
        await cancelFocusSession();
      }

      final now = DateTime.now();
      final endTime = now.add(Duration(seconds: durationInSeconds));

      _currentSession = FocusSessionData(
        id: 0, // Auto-generated
        sessionType: sessionType,
        startTime: now,
        endTime: null, // Will be set when completed
        durationInSeconds: durationInSeconds,
        pausedDurationInSeconds: 0,
        mode: mode.name,
        status: 'active',
        notes: null,
        isCalendarTriggered: triggeringCalendarEventId != null,
        triggeringCalendarEventId: triggeringCalendarEventId,
      );

      await _db.insertFocusSession(
        FocusSessionsCompanion(
          sessionType: Value(sessionType),
          startTime: Value(now),
          durationInSeconds: Value(durationInSeconds),
          mode: Value(mode.name),
          status: const Value('active'),
          isCalendarTriggered: Value(triggeringCalendarEventId != null),
          triggeringCalendarEventId: Value(triggeringCalendarEventId),
        ),
      );

      _status = FocusStatus.active;
      _remainingSeconds = durationInSeconds;

      // Enable app blocking and DND
      await _androidService.enableDND();
      await _androidService.enableAppBlocking(session: _currentSession!);

      _startFocusTimer();
      notifyListeners();

      debugPrint('[FocusModeManager] Session started: $sessionType (${mode.name})');
    } catch (e) {
      debugPrint('[FocusModeManager] Error starting session: $e');
    }
  }

  /// Auto-start focus mode based on calendar event
  Future<void> autoStartFromCalendarEvent(
      CachedCalendarEventData event) async {
    debugPrint('[FocusModeManager] Auto-starting from calendar event: ${event.eventTitle}');

    final duration =
        event.endTime.difference(event.startTime).inSeconds;

    await startFocusSession(
      sessionType: 'Focus: ${event.eventTitle}',
      mode: FocusMode.stopwatch,
      durationInSeconds: duration,
      triggeringCalendarEventId: event.eventId,
    );
  }

  /// Pause focus session
  Future<void> pauseFocusSession() async {
    if (_currentSession == null || _status != FocusStatus.active) return;

    _focusTimer?.cancel();
    _status = FocusStatus.paused;

    final updated = _currentSession!.copyWith(
      status: 'paused',
      pausedDurationInSeconds: _currentSession!.pausedDurationInSeconds + _remainingSeconds,
    );

    await _db.updateFocusSession(updated);
    _currentSession = updated;

    notifyListeners();
    debugPrint('[FocusModeManager] Session paused');
  }

  /// Resume focus session
  Future<void> resumeFocusSession() async {
    if (_currentSession == null || _status != FocusStatus.paused) return;

    _status = FocusStatus.active;
    _startFocusTimer();

    final updated = _currentSession!.copyWith(status: 'active');
    await _db.updateFocusSession(updated);
    _currentSession = updated;

    notifyListeners();
    debugPrint('[FocusModeManager] Session resumed');
  }

  /// Complete focus session
  Future<void> completeFocusSession({String? notes}) async {
    if (_currentSession == null) return;

    _focusTimer?.cancel();

    final now = DateTime.now();
    final updated = _currentSession!.copyWith(
      endTime: now,
      status: 'completed',
      notes: notes,
    );

    await _db.updateFocusSession(updated);
    _currentSession = null;
    _status = FocusStatus.completed;
    _remainingSeconds = 0;

    // Disable app blocking and DND
    await _androidService.disableDND();
    await _androidService.disableAppBlocking();

    notifyListeners();
    debugPrint('[FocusModeManager] Session completed');
  }

  /// Cancel focus session
  Future<void> cancelFocusSession() async {
    if (_currentSession == null) return;

    _focusTimer?.cancel();

    await _db.cancelFocusSession(_currentSession!.id);
    _currentSession = null;
    _status = FocusStatus.cancelled;
    _remainingSeconds = 0;

    // Disable app blocking and DND
    await _androidService.disableDND();
    await _androidService.disableAppBlocking();

    notifyListeners();
    debugPrint('[FocusModeManager] Session cancelled');
  }

  /// Monitor calendar for active events and auto-start focus
  Future<void> startCalendarMonitoring() async {
    final integration = await _db.getCalendarIntegration();
    if (integration == null || !integration.isAutoFocusEnabled) {
      debugPrint('[FocusModeManager] Calendar monitoring not enabled');
      return;
    }

    // Check every 30 seconds for active calendar events
    Timer.periodic(const Duration(seconds: 30), (_) async {
      final activeEvents = await _calendarService.getActiveEvents();

      // If there's an active event and no focus session, auto-start
      if (activeEvents.isNotEmpty && !isActive) {
        final event = activeEvents.first;
        await autoStartFromCalendarEvent(event);
      }

      // If focus session was calendar-triggered but event ended, auto-complete
      if (isActive &&
          _currentSession!.isCalendarTriggered &&
          activeEvents.isEmpty) {
        await completeFocusSession();
      }
    });

    debugPrint('[FocusModeManager] Calendar monitoring started');
  }

  /// Internal timer tick handler
  void _startFocusTimer() {
    _focusTimer?.cancel();

    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != FocusStatus.active) return;

      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        completeFocusSession();
      } else {
        notifyListeners();
      }
    });
  }

  /// Calculate remaining time for an existing session
  int _calculateRemainingSeconds(FocusSessionData session) {
    final elapsed = DateTime.now().difference(session.startTime).inSeconds;
    return (session.durationInSeconds - elapsed).clamp(0, session.durationInSeconds);
  }

  /// Get today's focus sessions
  Future<List<FocusSessionData>> getTodaysSessions() {
    return _db.getTodaysFocusSessions();
  }

  /// Get total focus time today (in seconds)
  Future<int> getTodaysFocusTime() async {
    final sessions = await getTodaysSessions();
    return sessions
        .where((s) => s.status == 'completed')
        .fold(0, (sum, s) => sum + s.durationInSeconds);
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }
}
