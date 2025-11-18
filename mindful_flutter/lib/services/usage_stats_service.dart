import 'package:flutter/foundation.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';
import 'package:mindful/services/android_service.dart';
import 'dart:async';

class UsageStatsService {
  final AppDatabase _db;
  final AndroidService _androidService;
  
  Timer? _usageCheckTimer;
  Timer? _analyticsUpdateTimer;

  UsageStatsService(this._db, this._androidService);

  /// Start monitoring app usage
  Future<void> startUsageMonitoring() async {
    // Check every 5 minutes
    _usageCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _updateAppUsageStats();
    });

    // Update daily analytics every hour
    _analyticsUpdateTimer =
        Timer.periodic(const Duration(hours: 1), (_) async {
      await _updateDailyAnalytics();
    });

    debugPrint('[UsageStatsService] Usage monitoring started');
  }

  /// Stop monitoring app usage
  Future<void> stopUsageMonitoring() async {
    _usageCheckTimer?.cancel();
    _analyticsUpdateTimer?.cancel();
    debugPrint('[UsageStatsService] Usage monitoring stopped');
  }

  /// Update app usage statistics
  Future<void> _updateAppUsageStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get usage stats from Android
      final stats =
          await _androidService.getAppUsageStats(
        startDate: todayStart,
        endDate: now,
      );

      // Get all app limits
      final appLimits = await _db.getAllAppLimits();

      // Check each app's usage
      for (final limit in appLimits) {
        final usageInMs = stats[limit.packageName] ?? 0;
        final usageInSeconds = (usageInMs / 1000).toInt();

        // Update app's used time
        await _db.updateAppUsedTime(limit.packageName, usageInSeconds);

        // Check if limit exceeded
        if (limit.usedTimeToday >= limit.dailyLimitInMinutes * 60) {
          // Block the app
          await _db.setAppBlockStatus(
            limit.packageName,
            true,
            reason: 'time_limit',
          );

          // Show notification (handled elsewhere)
        } else if (!limit.isBlocked) {
          // Keep it unblocked
          await _db.setAppBlockStatus(limit.packageName, false);
        }
      }

      debugPrint('[UsageStatsService] Updated app usage stats');
    } catch (e) {
      debugPrint('[UsageStatsService] Error updating usage stats: $e');
    }
  }

  /// Update daily analytics
  Future<void> _updateDailyAnalytics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get or create today's usage record
      var todayUsage = await _db.getTodayUsage();

      if (todayUsage == null) {
        // Create new record
        await _db.insertDailyUsage(
          DailyUsageRecordsCompanion(
            date: Value(today),
            totalScreenTimeInSeconds: const Value(0),
            focusSessionTimeInSeconds: const Value(0),
          ),
        );
        todayUsage = await _db.getTodayUsage();
      }

      if (todayUsage != null) {
        // Get total screen time from Android
        final screenTimeMs = await _androidService.getTodayScreenTime();
        final screenTimeSeconds = (screenTimeMs / 1000).toInt();

        // Get today's focus sessions
        final todaysSessions = await _db.getTodaysFocusSessions();
        final focusTimeSeconds = todaysSessions
            .where((s) => s.status == 'completed')
            .fold<int>(0, (sum, s) => sum + s.durationInSeconds);

        // Update record
        final updated = todayUsage.copyWith(
          totalScreenTimeInSeconds: screenTimeSeconds,
          focusSessionTimeInSeconds: focusTimeSeconds,
        );

        await _db.updateDailyUsage(updated);
        debugPrint('[UsageStatsService] Updated daily analytics');
      }
    } catch (e) {
      debugPrint('[UsageStatsService] Error updating analytics: $e');
    }
  }

  /// Helper to update daily usage
  Future<void> updateDailyUsage(DailyUsageData updated) async {
    // This would need to be added to AppDatabase if not present
    // For now, using insertOrUpdate pattern
  }

  /// Get app usage breakdown for today
  Future<Map<String, int>> getTodayAppBreakdown() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final stats = await _androidService.getAppUsageStats(
        startDate: todayStart,
        endDate: now,
      );

      return stats.map((app, ms) => MapEntry(app, (ms / 1000).toInt()));
    } catch (e) {
      debugPrint('[UsageStatsService] Error getting app breakdown: $e');
      return {};
    }
  }

  /// Get weekly statistics
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final weeklyRecords = await _db.getWeeklyUsage();

      if (weeklyRecords.isEmpty) {
        return {
          'avgDailyScreenTime': 0,
          'totalFocusTime': 0,
          'mostUsedDay': '',
          'records': [],
        };
      }

      final totalScreenTime =
          weeklyRecords.fold<int>(0, (sum, r) => sum + r.totalScreenTimeInSeconds);
      final avgDailyScreenTime = totalScreenTime ~/ weeklyRecords.length;

      final totalFocusTime =
          weeklyRecords.fold<int>(0, (sum, r) => sum + r.focusSessionTimeInSeconds);

      final mostUsedDay = weeklyRecords.reduce((a, b) =>
          a.totalScreenTimeInSeconds > b.totalScreenTimeInSeconds ? a : b);

      return {
        'avgDailyScreenTime': avgDailyScreenTime,
        'totalFocusTime': totalFocusTime,
        'mostUsedDay': _formatDate(mostUsedDay.date),
        'records': weeklyRecords,
      };
    } catch (e) {
      debugPrint('[UsageStatsService] Error getting weekly stats: $e');
      return {};
    }
  }

  /// Get insight recommendations
  Future<List<String>> getInsights() async {
    try {
      final insights = <String>[];
      final weeklyStats = await getWeeklyStats();
      final avgScreenTime = weeklyStats['avgDailyScreenTime'] as int? ?? 0;
      final totalFocusTime = weeklyStats['totalFocusTime'] as int? ?? 0;

      // Insight: High screen time
      if (avgScreenTime > 7 * 3600) {
        // > 7 hours
        insights.add('Your average daily screen time is quite high. Consider using Focus Mode more often.');
      }

      // Insight: Good focus time
      if (totalFocusTime > 15 * 3600) {
        // > 15 hours
        insights.add('Great job! You\'ve spent significant time in Focus Mode this week.');
      }

      // Insight: No focus sessions
      if (totalFocusTime == 0) {
        insights.add('Start your first Focus Mode session to boost productivity!');
      }

      // Insight: Best time
      insights.add('Your most productive day was ${weeklyStats['mostUsedDay']}.');

      return insights;
    } catch (e) {
      debugPrint('[UsageStatsService] Error getting insights: $e');
      return [];
    }
  }

  String _formatDate(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  void dispose() {
    _usageCheckTimer?.cancel();
    _analyticsUpdateTimer?.cancel();
  }
}
