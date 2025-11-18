package com.neubofy.mindful.utils

import android.content.Context
import android.app.NotificationManager
import android.os.Build
import androidx.annotation.RequiresApi
import android.util.Log

class DndHelper(private val context: Context) {
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @RequiresApi(Build.VERSION_CODES.M)
    fun enableDND(): Boolean {
        return try {
            // Set DND mode to priority only (messages and calls from starred contacts)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
            } else {
                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            }
            Log.d("DndHelper", "DND enabled")
            true
        } catch (e: Exception) {
            Log.e("DndHelper", "Error enabling DND", e)
            false
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    fun disableDND(): Boolean {
        return try {
            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
            Log.d("DndHelper", "DND disabled")
            true
        } catch (e: Exception) {
            Log.e("DndHelper", "Error disabling DND", e)
            false
        }
    }
}
