import 'package:drift/drift.dart';

// ============== FOCUS SESSION ==============
@DataClassName('FocusSessionData')
class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get sessionType => text()(); // 'Study', 'Work', 'Creative', 'Break'
  
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  
  IntColumn get durationInSeconds => integer()();
  IntColumn get pausedDurationInSeconds => integer().withDefault(const Constant(0))();
  
  TextColumn get mode => text().withDefault(const Constant('countdown'))(); // 'countdown', 'stopwatch'
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active', 'paused', 'completed', 'cancelled'
  
  TextColumn get notes => text().nullable()();
  BoolColumn get isCalendarTriggered => boolColumn().withDefault(const Constant(false))();
  TextColumn get triggeringCalendarEventId => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
  @override
  Set<Column> get uniqueKeys => {
    {startTime}
  };
}

// ============== APP USAGE LIMIT ==============
@DataClassName('AppUsageLimitData')
class AppUsageLimits extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  
  IntColumn get dailyLimitInMinutes => integer()();
  IntColumn get usedTimeToday => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get resetTime => dateTime().withDefault(Constant(DateTime.now()))();
  
  BoolColumn get isBlocked => boolColumn().withDefault(const Constant(false))();
  BoolColumn get isInvincibleMode => boolColumn().withDefault(const Constant(false))();
  TextColumn get groupId => text().nullable()(); // For shared limits
  
  @override
  Set<Column> get primaryKey => {id};
  @override
  Set<Column> get uniqueKeys => {
    {packageName}
  };
}

// ============== APP GROUP (SHARED LIMITS) ==============
@DataClassName('AppGroupData')
class AppGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get groupName => text()();
  TextColumn get groupId => text().unique()();
  
  IntColumn get groupLimitInMinutes => integer()();
  IntColumn get usedTimeToday => integer().withDefault(const Constant(0))();
  
  BoolColumn get isInvincibleMode => boolColumn().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== DAILY USAGE ANALYTICS ==============
@DataClassName('DailyUsageData')
class DailyUsageRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  DateTimeColumn get date => dateTime()();
  
  IntColumn get totalScreenTimeInSeconds => integer().withDefault(const Constant(0))();
  IntColumn get focusSessionTimeInSeconds => integer().withDefault(const Constant(0))();
  IntColumn get dataUsedInMB => integer().withDefault(const Constant(0))();
  
  IntColumn get appUnlocksCount => integer().withDefault(const Constant(0))();
  IntColumn get notificationCount => integer().withDefault(const Constant(0))();
  
  TextColumn get topAppsByTime => text().nullable()(); // JSON serialized list
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== NOTIFICATION RULE ==============
@DataClassName('NotificationRuleData')
class NotificationRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get appPackageName => text().nullable()(); // null = all apps
  
  TextColumn get action => text()(); // 'mute', 'batch', 'schedule', 'allow'
  BoolColumn get isEnabled => boolColumn().withDefault(const Constant(true))();
  
  IntColumn get batchDelayInMinutes => integer().nullable()();
  TextColumn get scheduleStart => text().nullable()(); // 'HH:mm' format
  TextColumn get scheduleEnd => text().nullable()(); // 'HH:mm' format
  
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== BEDTIME MODE ==============
@DataClassName('BedtimeModeData')
class BedtimeModes extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  BoolColumn get isEnabled => boolColumn().withDefault(const Constant(true))();
  TextColumn get startTime => text()(); // 'HH:mm' format
  TextColumn get endTime => text()(); // 'HH:mm' format
  
  BoolColumn get pauseApps => boolColumn().withDefault(const Constant(true))();
  BoolColumn get enableDND => boolColumn().withDefault(const Constant(true))();
  BoolColumn get blockInternet => boolColumn().withDefault(const Constant(false))();
  
  TextColumn get excludedApps => text().nullable()(); // JSON serialized list
  
  DateTimeColumn get lastActivatedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== PARENTAL CONTROL ==============
@DataClassName('ParentalControlData')
class ParentalControls extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  BoolColumn get isEnabled => boolColumn().withDefault(const Constant(false))();
  TextColumn get biometricPin => text().nullable()(); // Encrypted
  
  BoolColumn get requireBiometricForDisable => boolColumn().withDefault(const Constant(true))();
  BoolColumn get tamperProofMode => boolColumn().withDefault(const Constant(true))();
  
  IntColumn get maxDailyScreenTimeInMinutes => integer().withDefault(const Constant(180))();
  TextColumn get restrictedApps => text().nullable()(); // JSON serialized list
  
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== INTERNET BLOCKING ==============
@DataClassName('InternetBlockData')
class InternetBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get appPackageName => text().nullable()(); // null = all apps
  
  DateTimeColumn get blockedAt => dateTime()();
  DateTimeColumn get unblockAt => dateTime().nullable()();
  
  BoolColumn get isActive => boolColumn().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== ADULT CONTENT FILTER ==============
@DataClassName('AdultContentFilterData')
class AdultContentFilters extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  BoolColumn get isEnabled => boolColumn().withDefault(const Constant(false))();
  TextColumn get blockedApps => text().nullable()(); // JSON serialized list of package names
  TextColumn get blockedWebsites => text().nullable()(); // JSON serialized list of domains
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== GOOGLE CALENDAR INTEGRATION ==============
@DataClassName('CalendarIntegrationData')
class CalendarIntegrations extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  BoolColumn get isConnected => boolColumn().withDefault(const Constant(false))();
  TextColumn get accessToken => text().nullable(); // Encrypted in secure storage
  TextColumn get refreshToken => text().nullable(); // Encrypted in secure storage
  
  DateTimeColumn get tokenExpiryAt => dateTime().nullable()();
  TextColumn get userEmail => text().nullable()();
  
  BoolColumn get isAutoFocusEnabled => boolColumn().withDefault(const Constant(false))();
  
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== CACHED CALENDAR EVENTS ==============
@DataClassName('CachedCalendarEventData')
class CachedCalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get eventId => text().unique()();
  TextColumn get eventTitle => text()();
  TextColumn get eventDescription => text().nullable()();
  
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  
  TextColumn get calendarId => text()();
  BoolColumn get isAllDay => boolColumn().withDefault(const Constant(false))();
  
  DateTimeColumn get cachedAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get expiresAt => dateTime()(); // For cache invalidation
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== CALENDAR SYNC LOG ==============
@DataClassName('CalendarSyncLogData')
class CalendarSyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  DateTimeColumn get syncTime => dateTime()();
  IntColumn get eventsCount => integer()();
  
  TextColumn get status => text()(); // 'success', 'failed', 'partial'
  TextColumn get errorMessage => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== APP BLOCKING STATUS ==============
@DataClassName('AppBlockStatusData')
class AppBlockStatuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get appPackageName => text().unique()();
  BoolColumn get isBlocked => boolColumn().withDefault(const Constant(false))();
  
  DateTimeColumn get blockedAt => dateTime().nullable()();
  TextColumn get blockReason => text().nullable()(); // 'focus_mode', 'time_limit', 'manual', 'bedtime'
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============== SETTINGS ==============
@DataClassName('SettingsData')
class SettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  BoolColumn get isDarkMode => boolColumn().withDefault(const Constant(false))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  
  BoolColumn get areNotificationsEnabled => boolColumn().withDefault(const Constant(true))();
  BoolColumn get isAnalyticsEnabled => boolColumn().withDefault(const Constant(true))();
  
  TextColumn get theme => text().withDefault(const Constant('system'))(); // 'light', 'dark', 'system'
  
  @override
  Set<Column> get primaryKey => {id};
}
