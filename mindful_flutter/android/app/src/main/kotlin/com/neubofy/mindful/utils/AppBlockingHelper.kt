package com.neubofy.mindful.utils

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log

class AppBlockingHelper(private val context: Context) {
    private val packageManager = context.packageManager
    private val blockedApps = mutableSetOf<String>()
    private var isBlockingEnabled = false

    fun blockApp(packageName: String): Boolean {
        return try {
            blockedApps.add(packageName)
            Log.d("AppBlockingHelper", "App blocked: $packageName")
            true
        } catch (e: Exception) {
            Log.e("AppBlockingHelper", "Error blocking app", e)
            false
        }
    }

    fun unblockApp(packageName: String): Boolean {
        return try {
            blockedApps.remove(packageName)
            Log.d("AppBlockingHelper", "App unblocked: $packageName")
            true
        } catch (e: Exception) {
            Log.e("AppBlockingHelper", "Error unblocking app", e)
            false
        }
    }

    fun enableBlocking(): Boolean {
        return try {
            isBlockingEnabled = true
            Log.d("AppBlockingHelper", "App blocking enabled for ${blockedApps.size} apps")
            true
        } catch (e: Exception) {
            Log.e("AppBlockingHelper", "Error enabling blocking", e)
            false
        }
    }

    fun disableBlocking(): Boolean {
        return try {
            isBlockingEnabled = false
            blockedApps.clear()
            Log.d("AppBlockingHelper", "App blocking disabled")
            true
        } catch (e: Exception) {
            Log.e("AppBlockingHelper", "Error disabling blocking", e)
            false
        }
    }

    fun getBlockedApps(): Set<String> {
        return blockedApps.toSet()
    }

    fun isBlocked(packageName: String): Boolean {
        return isBlockingEnabled && blockedApps.contains(packageName)
    }
}
