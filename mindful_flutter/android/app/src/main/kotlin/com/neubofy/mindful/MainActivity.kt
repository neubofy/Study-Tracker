package com.neubofy.mindful

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.neubofy.mindful.services.CalendarMonitoringService
import com.neubofy.mindful.utils.BiometricHelper
import com.neubofy.mindful.utils.DndHelper
import com.neubofy.mindful.utils.AppBlockingHelper
import com.neubofy.mindful.utils.VpnHelper
import com.neubofy.mindful.utils.UsageStatsHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private lateinit var methodChannel: MethodChannel
    private lateinit var dndHelper: DndHelper
    private lateinit var appBlockingHelper: AppBlockingHelper
    private lateinit var vpnHelper: VpnHelper
    private lateinit var usageStatsHelper: UsageStatsHelper
    private lateinit var biometricHelper: BiometricHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize helpers
        dndHelper = DndHelper(this)
        appBlockingHelper = AppBlockingHelper(this)
        vpnHelper = VpnHelper(this)
        usageStatsHelper = UsageStatsHelper(this)
        biometricHelper = BiometricHelper(this)

        // Setup method channel for Flutter -> Native communication
        setupMethodChannel(flutterEngine)
    }

    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.neubofy.mindful/native"
        )

        methodChannel.setMethodCallHandler { call, result ->
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
