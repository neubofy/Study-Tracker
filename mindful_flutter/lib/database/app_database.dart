import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  FocusSessions,
  AppUsageLimits,
  AppGroups,
  DailyUsageRecords,
  NotificationRules,
  BedtimeModes,
  ParentalControls,
  InternetBlocks,
  AdultContentFilters,
  CalendarIntegrations,
  CachedCalendarEvents,
  CalendarSyncLogs,
  AppBlockStatuses,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here as schema evolves
      },
    );
  }

  // ============== FOCUS SESSIONS ==============
  Future<void> insertFocusSession(FocusSessionsCompanion session) {
    return into(focusSessions).insert(session);
  }

  Future<List<FocusSessionData>> getAllFocusSessions() {
    return select(focusSessions).get();
  }

  Future<List<FocusSessionData>> getTodaysFocusSessions() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return (select(focusSessions)
          ..where((tbl) =>
              tbl.startTime.isBiggerOrEqualValue(todayStart) &
              tbl.startTime.isSmallerThanValue(todayEnd)))
        .get();
  }

  Future<FocusSessionData?> getActiveFocusSession() {
    return (select(focusSessions)
          ..where((tbl) => tbl.status.equals('active'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.startTime, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateFocusSession(FocusSessionData session) {
    return update(focusSessions).replace(session);
  }

  Future<void> cancelFocusSession(int sessionId) {
    return (update(focusSessions)..where((tbl) => tbl.id.equals(sessionId)))
        .write(const FocusSessionsCompanion(status: Value('cancelled')));
  }

  // ============== APP USAGE LIMITS ==============
  Future<void> insertOrUpdateAppLimit(AppUsageLimitsCompanion limit) {
    return into(appUsageLimits).insertOnConflictUpdate(limit);
  }

  Future<AppUsageLimitData?> getAppLimit(String packageName) {
    return (select(appUsageLimits)
          ..where((tbl) => tbl.packageName.equals(packageName))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<AppUsageLimitData>> getAllAppLimits() {
    return select(appUsageLimits).get();
  }

  Future<List<AppUsageLimitData>> getBlockedApps() {
    return (select(appUsageLimits)..where((tbl) => tbl.isBlocked.equals(true)))
        .get();
  }

  Future<void> updateAppUsedTime(String packageName, int addedSeconds) async {
    final limit = await getAppLimit(packageName);
    if (limit != null) {
      final updated = limit.copyWith(
        usedTimeToday: limit.usedTimeToday + addedSeconds,
      );
      await update(appUsageLimits).replace(updated);
    }
  }

  // ============== APP GROUPS ==============
  Future<void> insertAppGroup(AppGroupsCompanion group) {
    return into(appGroups).insert(group);
  }

  Future<List<AppGroupData>> getAllAppGroups() {
    return select(appGroups).get();
  }

  Future<AppGroupData?> getAppGroup(String groupId) {
    return (select(appGroups)
          ..where((tbl) => tbl.groupId.equals(groupId))
          ..limit(1))
        .getSingleOrNull();
  }

  // ============== DAILY USAGE ANALYTICS ==============
  Future<void> insertDailyUsage(DailyUsageRecordsCompanion record) {
    return into(dailyUsageRecords).insert(record);
  }

  Future<DailyUsageData?> getTodayUsage() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return (select(dailyUsageRecords)
          ..where((tbl) => tbl.date.equals(today))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<DailyUsageData>> getWeeklyUsage() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return (select(dailyUsageRecords)
          ..where((tbl) =>
              tbl.date.isBiggerOrEqualValue(weekAgo) & tbl.date.isSmallerOrEqualValue(now)))
        .get();
  }

  // ============== NOTIFICATION RULES ==============
  Future<void> insertNotificationRule(NotificationRulesCompanion rule) {
    return into(notificationRules).insert(rule);
  }

  Future<List<NotificationRuleData>> getAllNotificationRules() {
    return (select(notificationRules)..where((tbl) => tbl.isEnabled.equals(true)))
        .get();
  }

  // ============== BEDTIME MODE ==============
  Future<BedtimeModeData?> getBedtimeMode() {
    return (select(bedtimeModes)..limit(1)).getSingleOrNull();
  }

  Future<void> insertOrUpdateBedtimeMode(BedtimeModesCompanion mode) {
    return into(bedtimeModes).insertOnConflictUpdate(mode);
  }

  // ============== PARENTAL CONTROLS ==============
  Future<ParentalControlData?> getParentalControl() {
    return (select(parentalControls)..limit(1)).getSingleOrNull();
  }

  Future<void> insertOrUpdateParentalControl(ParentalControlsCompanion control) {
    return into(parentalControls).insertOnConflictUpdate(control);
  }

  // ============== CALENDAR INTEGRATION ==============
  Future<CalendarIntegrationData?> getCalendarIntegration() {
    return (select(calendarIntegrations)..limit(1)).getSingleOrNull();
  }

  Future<void> insertOrUpdateCalendarIntegration(
      CalendarIntegrationsCompanion integration) {
    return into(calendarIntegrations).insertOnConflictUpdate(integration);
  }

  // ============== CACHED CALENDAR EVENTS ==============
  Future<void> insertCachedEvent(CachedCalendarEventsCompanion event) {
    return into(cachedCalendarEvents).insertOnConflictUpdate(event);
  }

  Future<List<CachedCalendarEventData>> getActiveCalendarEvents(DateTime now) {
    return (select(cachedCalendarEvents)
          ..where((tbl) =>
              tbl.startTime.isSmallerOrEqualValue(now) &
              tbl.endTime.isBiggerOrEqualValue(now) &
              tbl.expiresAt.isBiggerOrEqualValue(now)))
        .get();
  }

  Future<List<CachedCalendarEventData>> getUpcomingCalendarEvents(DateTime now) {
    return (select(cachedCalendarEvents)
          ..where((tbl) =>
              tbl.startTime.isBiggerOrEqualValue(now) &
              tbl.expiresAt.isBiggerOrEqualValue(now))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.startTime)]))
        .get();
  }

  Future<void> deleteCachedEventsBefore(DateTime expiryTime) {
    return (delete(cachedCalendarEvents)
          ..where((tbl) => tbl.expiresAt.isSmallerThanValue(expiryTime)))
        .go();
  }

  // ============== CALENDAR SYNC LOG ==============
  Future<void> insertCalendarSyncLog(CalendarSyncLogsCompanion log) {
    return into(calendarSyncLogs).insert(log);
  }

  // ============== APP BLOCK STATUSES ==============
  Future<void> setAppBlockStatus(String packageName, bool isBlocked,
      {String? reason}) {
    return into(appBlockStatuses).insertOnConflictUpdate(
      AppBlockStatusesCompanion(
        appPackageName: Value(packageName),
        isBlocked: Value(isBlocked),
        blockedAt: Value(isBlocked ? DateTime.now() : null),
        blockReason: Value(reason),
      ),
    );
  }

  Future<AppBlockStatusData?> getAppBlockStatus(String packageName) {
    return (select(appBlockStatuses)
          ..where((tbl) => tbl.appPackageName.equals(packageName))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<AppBlockStatusData>> getAllBlockedApps() {
    return (select(appBlockStatuses)..where((tbl) => tbl.isBlocked.equals(true)))
        .get();
  }

  // ============== SETTINGS ==============
  Future<SettingsData?> getSettings() {
    return (select(settingsTable)..limit(1)).getSingleOrNull();
  }

  Future<void> insertOrUpdateSettings(SettingsTableCompanion settings) {
    return into(settingsTable).insertOnConflictUpdate(settings);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mindful_app.db'));
    if (kDebugMode) {
      print('[DB] Database path: ${file.path}');
    }
    return NativeDatabase(file);
  });
}
