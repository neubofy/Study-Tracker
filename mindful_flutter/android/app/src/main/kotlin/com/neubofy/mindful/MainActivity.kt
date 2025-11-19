package com.neubofy.mindful

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // Flutter handles everything automatically in v2 embedding
}
            when (call.method) {
                // ========== DND Control ==========
                "enableDND" -> result.success(dndHelper.enableDND())
                "disableDND" -> result.success(dndHelper.disableDND())

                // ========== App Blocking ==========
                "blockApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(appBlockingHelper.blockApp(packageName))
                }
                "unblockApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(appBlockingHelper.unblockApp(packageName))
                }
                "enableAppBlocking" -> {
                    result.success(appBlockingHelper.enableBlocking())
                }
                "disableAppBlocking" -> {
                    result.success(appBlockingHelper.disableBlocking())
                }

                // ========== Internet Blocking ==========
                "blockInternet" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(vpnHelper.blockInternet(packageName))
                }
                "restoreInternet" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(vpnHelper.restoreInternet(packageName))
                }
                "startVPN" -> result.success(vpnHelper.startVPN())
                "stopVPN" -> result.success(vpnHelper.stopVPN())

                // ========== Usage Stats ==========
                "getAppUsageStats" -> {
                    val startDate = call.argument<Long>("startDate") ?: 0L
                    val endDate = call.argument<Long>("endDate") ?: 0L
                    val stats = usageStatsHelper.getAppUsageStats(startDate, endDate)
                    result.success(stats)
                }
                "getTodayScreenTime" -> {
                    val screenTime = usageStatsHelper.getTodayScreenTime()
                    result.success(screenTime)
                }
                "getInstalledApps" -> {
                    val apps = usageStatsHelper.getInstalledApps()
                    result.success(apps)
                }

                // ========== Biometric ==========
                "authenticateWithBiometric" -> {
                    val reason = call.argument<String>("reason") ?: "Authenticate"
                    biometricHelper.authenticate(reason) { success ->
                        result.success(success)
                    }
                }
                "isBiometricAvailable" -> {
                    result.success(biometricHelper.isBiometricAvailable())
                }

                // ========== Device Info ==========
                "getDeviceInfo" -> {
                    val info = mapOf(
                        "device" to Build.DEVICE,
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "sdk" to Build.VERSION.SDK_INT.toString(),
                        "version" to Build.VERSION.RELEASE
                    )
                    result.success(info)
                }

                // ========== Foreground Service ==========
                "startForegroundService" -> {
                    startCalendarMonitoringService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopCalendarMonitoringService()
                    result.success(true)
                }

                // ========== Adult Content Filter ==========
                "enableAdultContentFilter" -> {
                    val domains = call.argument<List<String>>("domains") ?: emptyList()
                    // Implement DNS filtering or app blocking for adult content
                    result.success(true)
                }
                "disableAdultContentFilter" -> {
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startCalendarMonitoringService() {
        try {
            val intent = Intent(this, CalendarMonitoringService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d("MainActivity", "Calendar monitoring service started")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error starting calendar service", e)
        }
    }

    private fun stopCalendarMonitoringService() {
        try {
            val intent = Intent(this, CalendarMonitoringService::class.java)
            stopService(intent)
            Log.d("MainActivity", "Calendar monitoring service stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping calendar service", e)
        }
    }

    companion object {
        private const val TAG = "MainActivity"
    }
}
