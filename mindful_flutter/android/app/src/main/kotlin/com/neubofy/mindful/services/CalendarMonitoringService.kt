package com.neubofy.mindful.services

import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import android.app.NotificationManager
import android.app.NotificationChannel

class CalendarMonitoringService : Service() {
    
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "calendar_monitoring_channel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("CalendarMonitoringService", "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("CalendarMonitoringService", "Service started")
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mindful - Calendar Monitoring")
            .setContentText("Monitoring your calendar events for focus mode...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForeground(NOTIFICATION_ID, notification)
        }

        // TODO: Implement actual calendar monitoring logic
        // This would involve:
        // 1. Reading calendar events from ContentProvider
        // 2. Checking for active events
        // 3. Triggering focus mode via method channel to Flutter

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("CalendarMonitoringService", "Service destroyed")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Calendar Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors calendar events for focus mode"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
