import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class GoogleCalendarService {
  // ⭐ OAuth Client ID from Google Cloud Console
  static const String _clientId =
      '263406133178-o51pr65tv6vi4nph7dhvprhi2fldj1bm.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar.readonly',
      'email',
    ],
    signInOption: SignInOption.standard,
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AppDatabase _db;

  calendar.CalendarApi? _calendarApi;
  Timer? _syncTimer;
  GoogleSignInAccount? _currentAccount;

  GoogleCalendarService(this._db);

  /// Get list of available Google accounts on device
  Future<List<GoogleSignInAccount>> getAvailableAccounts() async {
    try {
      // Request to see all accounts signed into the device
      await _googleSignIn.requestScopes([
        'https://www.googleapis.com/auth/calendar.readonly',
        'email',
      ]);
      
      // Get all accounts available on device
      final allAccounts = await _googleSignIn.signInSilently() as List<GoogleSignInAccount>?;
      return allAccounts ?? [];
    } catch (e) {
      debugPrint('[GoogleCalendarService] Error getting accounts: $e');
      return [];
    }
  }

  /// Connect with a specific email (simplified one-tap setup)
  Future<void> connectWithEmail(String email) async {
    try {
      // Sign in with the specific account
      final account = await _googleSignIn.signInSilently();
      
      if (account == null || account.email != email) {
        // If silent signin fails or wrong account, do manual signin
        await _googleSignIn.signOut();
        // Note: GoogleSignIn.signIn() will show account picker
        // User can select the email they want
      }

      _currentAccount = account;
      final authentication = await account?.authentication;
      
      if (authentication?.accessToken != null) {
        await _secureStorage.write(
          key: 'calendar_access_token',
          value: authentication!.accessToken,
        );
        if (authentication.idToken != null) {
          await _secureStorage.write(
            key: 'calendar_refresh_token',
            value: authentication.idToken!,
          );
        }

        _setupCalendarApi(authentication.accessToken!, authentication.idToken ?? '');

        // Save to database
        await _db.insertOrUpdateCalendarIntegration(
          CalendarIntegrationsCompanion(
            isConnected: const Value(true),
            accessToken: Value(authentication.accessToken),
            userEmail: Value(email),
            lastSyncAt: Value(DateTime.now()),
          ),
        );

        debugPrint('[GoogleCalendarService] Connected with $email');
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] Error connecting with email: $e');
      rethrow;
    }
  }

  /// Disconnect from Google Calendar
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: 'calendar_access_token');
      await _secureStorage.delete(key: 'calendar_refresh_token');

      await _db.insertOrUpdateCalendarIntegration(
        const CalendarIntegrationsCompanion(
          isConnected: Value(false),
          userEmail: Value(null),
        ),
      );

      _calendarApi = null;
      _syncTimer?.cancel();

      debugPrint('[GoogleCalendarService] Disconnected');
    } catch (e) {
      debugPrint('[GoogleCalendarService] Error disconnecting: $e');
    }
  }

  /// Initialize the service and restore session if available
  Future<void> initialize() async {
    try {
      final integration = await _db.getCalendarIntegration();
      
      if (integration != null && integration.isConnected) {
        // Restore from secure storage
        final accessToken =
            await _secureStorage.read(key: 'calendar_access_token');
        final refreshToken =
            await _secureStorage.read(key: 'calendar_refresh_token');

        if (accessToken != null && refreshToken != null) {
          _setupCalendarApi(accessToken, refreshToken);
          debugPrint('[GoogleCalendarService] Restored session');
        }
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] Error during initialization: $e');
    }
  }

  /// Sign in with Google and obtain calendar access
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      
      // Get credentials for API access
      await _secureStorage.write(
        key: 'calendar_access_token',
        value: auth.accessToken,
      );
      await _secureStorage.write(
        key: 'calendar_refresh_token',
        value: auth.idToken, // Note: idToken acts as refresh token
      );

      _setupCalendarApi(auth.accessToken!, auth.idToken!);

      // Save to database
      await _db.insertOrUpdateCalendarIntegration(
        CalendarIntegrationsCompanion(
          isConnected: const Value(true),
          accessToken: Value(auth.accessToken),
          userEmail: Value(account.email),
          lastSyncAt: Value(DateTime.now()),
        ),
      );

      debugPrint('[GoogleCalendarService] Sign in successful');
      return true;
    } catch (e) {
      debugPrint('[GoogleCalendarService] Sign in error: $e');
      return false;
    }
  }

  /// Sign out from Google Calendar
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: 'calendar_access_token');
      await _secureStorage.delete(key: 'calendar_refresh_token');

      await _db.insertOrUpdateCalendarIntegration(
        const CalendarIntegrationsCompanion(
          isConnected: Value(false),
          userEmail: Value(null),
        ),
      );

      _calendarApi = null;
      _syncTimer?.cancel();

      debugPrint('[GoogleCalendarService] Sign out successful');
    } catch (e) {
      debugPrint('[GoogleCalendarService] Sign out error: $e');
    }
  }

  /// Fetch calendar events for today and upcoming days
  Future<List<CachedCalendarEventData>> fetchCalendarEvents(
      {int daysAhead = 7}) async {
    if (_calendarApi == null) {
      debugPrint('[GoogleCalendarService] Calendar API not initialized');
      return [];
    }

    try {
      final now = DateTime.now();
      final maxDate = now.add(Duration(days: daysAhead));

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: now,
        timeMax: maxDate,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100,
      );

      final cachedEvents = <CachedCalendarEventData>[];

      if (events.items != null) {
        for (final event in events.items!) {
          // Skip all-day events or events without explicit times
          if (event.start == null || event.end == null) continue;
          if (event.start!.dateTime == null) continue; // Skip all-day events

          final startTime = event.start!.dateTime!;
          final endTime = event.end!.dateTime!;
          final expiresAt = endTime.add(const Duration(hours: 1)); // Cache for 1 hour after event

          final cachedEvent = CachedCalendarEventData(
            id: 0, // Will be auto-generated
            eventId: event.id!,
            eventTitle: event.summary ?? 'Untitled Event',
            eventDescription: event.description,
            startTime: startTime,
            endTime: endTime,
            calendarId: 'primary',
            isAllDay: false,
            cachedAt: now,
            expiresAt: expiresAt,
          );

          cachedEvents.add(cachedEvent);

          // Insert into database
          await _db.insertCachedEvent(
            CachedCalendarEventsCompanion(
              eventId: Value(event.id!),
              eventTitle: Value(event.summary ?? 'Untitled Event'),
              eventDescription: Value(event.description),
              startTime: Value(startTime),
              endTime: Value(endTime),
              calendarId: Value('primary'),
              isAllDay: Value(false),
              expiresAt: Value(expiresAt),
            ),
          );
        }
      }

      // Clean up expired events
      await _db.deleteCachedEventsBefore(now);

      // Log sync
      await _db.insertCalendarSyncLog(
        CalendarSyncLogsCompanion(
          syncTime: Value(now),
          eventsCount: Value(cachedEvents.length),
          status: const Value('success'),
        ),
      );

      // Update last sync time
      await _db.insertOrUpdateCalendarIntegration(
        const CalendarIntegrationsCompanion(
          lastSyncAt: Value(null), // Will be set by DB timestamp
        ),
      );

      debugPrint('[GoogleCalendarService] Fetched ${cachedEvents.length} events');
      return cachedEvents;
    } catch (e) {
      debugPrint('[GoogleCalendarService] Error fetching events: $e');

      await _db.insertCalendarSyncLog(
        CalendarSyncLogsCompanion(
          syncTime: Value(DateTime.now()),
          eventsCount: const Value(0),
          status: const Value('failed'),
          errorMessage: Value(e.toString()),
        ),
      );

      return [];
    }
  }

  /// Get currently active calendar events
  Future<List<CachedCalendarEventData>> getActiveEvents() async {
    final now = DateTime.now();
    final active = await _db.getActiveCalendarEvents(now);
    return active;
  }

  /// Get upcoming calendar events
  Future<List<CachedCalendarEventData>> getUpcomingEvents() async {
    final now = DateTime.now();
    return await _db.getUpcomingCalendarEvents(now);
  }

  /// Start periodic calendar sync
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(interval, (_) async {
      await fetchCalendarEvents();
    });

    debugPrint('[GoogleCalendarService] Started periodic sync every $interval');
  }

  /// Stop periodic calendar sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    debugPrint('[GoogleCalendarService] Stopped periodic sync');
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  /// Setup calendar API client
  void _setupCalendarApi(String accessToken, String refreshToken) {
    final credentials = auth.AccessCredentials(
      auth.AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1))),
      refreshToken,
      ['https://www.googleapis.com/auth/calendar.readonly'],
    );

    final client = auth.authenticatedClient(
      HttpClientForGoogle(),
      credentials,
    );

    _calendarApi = calendar.CalendarApi(client);
  }
}

/// Simple HTTP client wrapper for Google API
class HttpClientForGoogle implements http.Client {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _inner.get(url, headers: headers);
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    return _inner.head(url, headers: headers);
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _inner.post(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _inner.put(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _inner.patch(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _inner.delete(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  void close() {
    _inner.close();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    return _inner.read(url, headers: headers);
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    return _inner.readBytes(url, headers: headers);
  }
}
