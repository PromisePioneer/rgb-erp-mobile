package com.rgb.erp_mobile_new

import android.app.NotificationChannel
import android.app.NotificationManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Patrol Alarm Channel - High importance for alarm notifications
            val patrolAlarmChannel = NotificationChannel(
                "patrol_alarm",
                "Patrol Alarm",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Patrol checkpoint alarm notifications"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 500, 500, 500, 500, 500)
                setSound(
                    Uri.parse("android.resource://com.rgb.erp_mobile_new/raw/patrol_alarm"),
                    null
                )
                setBypassDnd(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(patrolAlarmChannel)

            // Default notification channel
            val defaultChannel = NotificationChannel(
                "default",
                "Default",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General notifications"
            }
            notificationManager.createNotificationChannel(defaultChannel)
        }
    }
}
