package com.neubofy.mindful.utils

import android.content.Context
import android.app.usage.UsageStatsManager
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import java.util.*

class UsageStatsHelper(private val context: Context) {
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private val packageManager = context.packageManager

    fun getAppUsageStats(startDate: Long, endDate: Long): Map<String, Long> {
        return try {
            val stats = mutableMapOf<String, Long>()
            val usageStatsList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startDate, endDate)

            usageStatsList?.forEach { usageStat ->
                stats[usageStat.packageName] = usageStat.totalTimeInForeground
            }

            Log.d("UsageStatsHelper", "Retrieved stats for ${stats.size} apps")
            stats
        } catch (e: Exception) {
            Log.e("UsageStatsHelper", "Error getting app usage stats", e)
            emptyMap()
        }
    }

    fun getTodayScreenTime(): Long {
        return try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            var totalScreenTime = 0L
            usageStatsList?.forEach { usageStat ->
                totalScreenTime += usageStat.totalTimeInForeground
            }

            Log.d("UsageStatsHelper", "Today screen time: ${totalScreenTime}ms")
            totalScreenTime
        } catch (e: Exception) {
            Log.e("UsageStatsHelper", "Error getting screen time", e)
            0L
        }
    }

    fun getInstalledApps(): List<Map<String, Any>> {
        return try {
            val apps = mutableListOf<Map<String, Any>>()
            val packageList = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

            packageList?.forEach { appInfo ->
                if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val icon = appInfo.loadIcon(packageManager)
                    
                    apps.add(
                        mapOf(
                            "packageName" to appInfo.packageName,
                            "appName" to appName,
                            "isSystem" to false
                        )
                    )
                }
            }

            Log.d("UsageStatsHelper", "Retrieved ${apps.size} non-system apps")
            apps
        } catch (e: Exception) {
            Log.e("UsageStatsHelper", "Error getting installed apps", e)
            emptyList()
        }
    }
}
