import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    _flutterLocalNotificationsPlugin.initialize(initSettings);
    _createNotificationChannels();
  }

  void _createNotificationChannels() {
    const AndroidNotificationChannel focusChannel = AndroidNotificationChannel(
      id: 'focus_mode_channel',
      name: 'Focus Mode',
      description: 'Notifications for focus mode sessions',
      importance: Importance.default,
    );

    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      id: 'reminder_channel',
      name: 'Reminders',
      description: 'Reminders and alerts',
      importance: Importance.default,
    );

    const AndroidNotificationChannel warningChannel = AndroidNotificationChannel(
      id: 'warning_channel',
      name: 'Warnings',
      description: 'Warning notifications',
      importance: Importance.high,
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(focusChannel);

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(warningChannel);
  }

  Future<void> showFocusNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'focus_mode_channel',
      'Focus Mode',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.default,
      priority: Priority.default,
      autoCancel: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      notificationDetails,
    );

    debugPrint('[NotificationService] Focus notification shown: $title');
  }

  Future<void> showSessionStartedNotification(String sessionType) async {
    await showFocusNotification(
      title: 'Focus Mode Started',
      body: 'Your $sessionType session has started',
    );
  }

  Future<void> showSessionEndedNotification(String sessionType) async {
    await showFocusNotification(
      title: 'Focus Mode Completed',
      body: 'Great work on your $sessionType session!',
    );
  }

  Future<void> showTimeLimitWarning(String appName, int minutesRemaining) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'warning_channel',
      'Warnings',
      channelDescription: 'Warning notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      2,
      'Screen Time Limit Warning',
      '$appName - $minutesRemaining minutes remaining',
      notificationDetails,
    );

    debugPrint('[NotificationService] Time limit warning: $appName');
  }

  Future<void> showTimeLimitExceeded(String appName) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'warning_channel',
      'Warnings',
      channelDescription: 'Warning notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      3,
      'Screen Time Limit Exceeded',
      '$appName has exceeded today\'s limit. App is now blocked.',
      notificationDetails,
    );

    debugPrint('[NotificationService] Limit exceeded: $appName');
  }

  Future<void> showCalendarEventReminder(String eventTitle) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.default,
      priority: Priority.default,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      4,
      'Upcoming Calendar Event',
      '$eventTitle is starting soon. Auto-focus will be enabled.',
      notificationDetails,
    );

    debugPrint('[NotificationService] Calendar reminder: $eventTitle');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String channelId = 'reminder_channel',
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelId == 'reminder_channel' ? 'Reminders' : 'Focus Mode',
      importance: Importance.default,
      priority: Priority.default,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[NotificationService] Scheduled notification: $title at $scheduledTime');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('[NotificationService] Cancelled notification: $id');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('[NotificationService] Cancelled all notifications');
  }
}
