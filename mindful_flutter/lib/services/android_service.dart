import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mindful/database/schema.dart';

class AndroidService {
  static const platform = MethodChannel('com.neubofy.mindful/native');

  /// Enable Do Not Disturb mode
  Future<bool> enableDND() async {
    try {
      final result = await platform.invokeMethod<bool>('enableDND');
      debugPrint('[AndroidService] DND enabled: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error enabling DND: $e');
      return false;
    }
  }

  /// Disable Do Not Disturb mode
  Future<bool> disableDND() async {
    try {
      final result = await platform.invokeMethod<bool>('disableDND');
      debugPrint('[AndroidService] DND disabled: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error disabling DND: $e');
      return false;
    }
  }

  /// Enable app blocking for a specific app
  Future<bool> blockApp(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>('blockApp', {
        'packageName': packageName,
      });
      debugPrint('[AndroidService] App blocked: $packageName');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error blocking app: $e');
      return false;
    }
  }

  /// Unblock a specific app
  Future<bool> unblockApp(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>('unblockApp', {
        'packageName': packageName,
      });
      debugPrint('[AndroidService] App unblocked: $packageName');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error unblocking app: $e');
      return false;
    }
  }

  /// Enable app blocking for focus session
  Future<bool> enableAppBlocking({required FocusSessionData session}) async {
    try {
      // This will be expanded to block specific apps based on configuration
      final result = await platform.invokeMethod<bool>('enableAppBlocking', {
        'reason': 'focus_mode',
        'sessionType': session.sessionType,
      });
      debugPrint('[AndroidService] App blocking enabled for: ${session.sessionType}');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error enabling app blocking: $e');
      return false;
    }
  }

  /// Disable app blocking
  Future<bool> disableAppBlocking() async {
    try {
      final result = await platform.invokeMethod<bool>('disableAppBlocking');
      debugPrint('[AndroidService] App blocking disabled');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error disabling app blocking: $e');
      return false;
    }
  }

  /// Block internet for a specific app
  Future<bool> blockInternet(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>('blockInternet', {
        'packageName': packageName,
      });
      debugPrint('[AndroidService] Internet blocked for: $packageName');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error blocking internet: $e');
      return false;
    }
  }

  /// Restore internet for a specific app
  Future<bool> restoreInternet(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>('restoreInternet', {
        'packageName': packageName,
      });
      debugPrint('[AndroidService] Internet restored for: $packageName');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error restoring internet: $e');
      return false;
    }
  }

  /// Get list of installed apps with usage stats
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await platform.invokeMethod<List>('getInstalledApps');
      final apps = result
          ?.map((app) => Map<String, dynamic>.from(app as Map))
          .toList() ?? [];
      debugPrint('[AndroidService] Retrieved ${apps.length} installed apps');
      return apps;
    } catch (e) {
      debugPrint('[AndroidService] Error getting installed apps: $e');
      return [];
    }
  }

  /// Get app usage stats for a specific date range
  Future<Map<String, int>> getAppUsageStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await platform.invokeMethod<Map>('getAppUsageStats', {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      });
      
      final stats = Map<String, int>.from(
        result?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      );
      
      debugPrint('[AndroidService] Retrieved usage stats for ${stats.length} apps');
      return stats;
    } catch (e) {
      debugPrint('[AndroidService] Error getting app usage stats: $e');
      return {};
    }
  }

  /// Get screen time for today
  Future<int> getTodayScreenTime() async {
    try {
      final result = await platform.invokeMethod<int>('getTodayScreenTime');
      debugPrint('[AndroidService] Today screen time: ${result}ms');
      return result ?? 0;
    } catch (e) {
      debugPrint('[AndroidService] Error getting screen time: $e');
      return 0;
    }
  }

  /// Enable local VPN for internet blocking
  Future<bool> startVPN() async {
    try {
      final result = await platform.invokeMethod<bool>('startVPN');
      debugPrint('[AndroidService] VPN started: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error starting VPN: $e');
      return false;
    }
  }

  /// Disable local VPN
  Future<bool> stopVPN() async {
    try {
      final result = await platform.invokeMethod<bool>('stopVPN');
      debugPrint('[AndroidService] VPN stopped: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error stopping VPN: $e');
      return false;
    }
  }

  /// Filter adult content
  Future<bool> enableAdultContentFilter(List<String> domains) async {
    try {
      final result = await platform.invokeMethod<bool>('enableAdultContentFilter', {
        'domains': domains,
      });
      debugPrint('[AndroidService] Adult content filter enabled');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error enabling adult filter: $e');
      return false;
    }
  }

  /// Disable adult content filter
  Future<bool> disableAdultContentFilter() async {
    try {
      final result = await platform.invokeMethod<bool>('disableAdultContentFilter');
      debugPrint('[AndroidService] Adult content filter disabled');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error disabling adult filter: $e');
      return false;
    }
  }

  /// Request biometric authentication
  Future<bool> authenticateWithBiometric(String reason) async {
    try {
      final result = await platform.invokeMethod<bool>('authenticateWithBiometric', {
        'reason': reason,
      });
      debugPrint('[AndroidService] Biometric auth result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error with biometric auth: $e');
      return false;
    }
  }

  /// Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    try {
      final result = await platform.invokeMethod<bool>('isBiometricAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error checking biometric: $e');
      return false;
    }
  }

  /// Get device information
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final result = await platform.invokeMethod<Map>('getDeviceInfo');
      final info = Map<String, String>.from(
        result?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      );
      return info;
    } catch (e) {
      debugPrint('[AndroidService] Error getting device info: $e');
      return {};
    }
  }

  /// Schedule foreground service for calendar monitoring
  Future<bool> startForegroundService() async {
    try {
      final result = await platform.invokeMethod<bool>('startForegroundService');
      debugPrint('[AndroidService] Foreground service started: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error starting foreground service: $e');
      return false;
    }
  }

  /// Stop foreground service
  Future<bool> stopForegroundService() async {
    try {
      final result = await platform.invokeMethod<bool>('stopForegroundService');
      debugPrint('[AndroidService] Foreground service stopped: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[AndroidService] Error stopping foreground service: $e');
      return false;
    }
  }
}
