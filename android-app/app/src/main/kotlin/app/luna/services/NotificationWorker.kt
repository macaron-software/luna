package app.luna.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.work.*
import app.luna.R
import app.luna.ui.MainActivity
import java.util.concurrent.TimeUnit

/**
 * NotificationWorker — notifications locales LUNA via WorkManager.
 * Aucune donnée transmise hors device.
 */
class NotificationWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    companion object {
        const val CHANNEL_PERIOD  = "luna_period"
        const val CHANNEL_FERTILE = "luna_fertile"
        const val CHANNEL_PILL    = "luna_pill"
        const val KEY_TYPE        = "notif_type"
        const val TYPE_PERIOD     = "period"
        const val TYPE_FERTILE    = "fertile"
        const val TYPE_PILL       = "pill"

        fun createChannels(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            listOf(
                NotificationChannel(CHANNEL_PERIOD,
                    context.getString(R.string.notif_channel_period),
                    NotificationManager.IMPORTANCE_DEFAULT),
                NotificationChannel(CHANNEL_FERTILE,
                    context.getString(R.string.notif_channel_fertile),
                    NotificationManager.IMPORTANCE_DEFAULT),
                NotificationChannel(CHANNEL_PILL,
                    context.getString(R.string.notif_channel_pill),
                    NotificationManager.IMPORTANCE_HIGH),
            ).forEach { nm.createNotificationChannel(it) }
        }

        fun schedulePillReminder(context: Context, hour: Int, minute: Int) {
            val now = java.util.Calendar.getInstance()
            val target = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, hour)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
            }
            if (target.before(now)) target.add(java.util.Calendar.DAY_OF_YEAR, 1)
            val delayMs = target.timeInMillis - now.timeInMillis

            val req = OneTimeWorkRequestBuilder<NotificationWorker>()
                .setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
                .setInputData(workDataOf(KEY_TYPE to TYPE_PILL))
                .addTag("luna_pill_reminder")
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                "luna_pill_daily", ExistingWorkPolicy.REPLACE, req)
        }

        fun schedulePeriodReminder(context: Context, daysUntilPeriod: Int) {
            if (daysUntilPeriod < 2) return
            val delayDays = (daysUntilPeriod - 2).toLong()
            val req = OneTimeWorkRequestBuilder<NotificationWorker>()
                .setInitialDelay(delayDays, TimeUnit.DAYS)
                .setInputData(workDataOf(KEY_TYPE to TYPE_PERIOD))
                .addTag("luna_period_reminder")
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                "luna_period_reminder", ExistingWorkPolicy.REPLACE, req)
        }

        fun cancelAll(context: Context) {
            WorkManager.getInstance(context).cancelAllWorkByTag("luna_pill_reminder")
            WorkManager.getInstance(context).cancelAllWorkByTag("luna_period_reminder")
        }
    }

    override suspend fun doWork(): Result {
        val type = inputData.getString(KEY_TYPE) ?: return Result.failure()
        val (title, body, channel, id) = when (type) {
            TYPE_PERIOD  -> arrayOf(
                applicationContext.getString(R.string.notif_period_title),
                applicationContext.getString(R.string.notif_period_body),
                CHANNEL_PERIOD, 1001
            )
            TYPE_FERTILE -> arrayOf(
                applicationContext.getString(R.string.notif_fertile_title),
                applicationContext.getString(R.string.notif_fertile_body),
                CHANNEL_FERTILE, 1002
            )
            TYPE_PILL    -> arrayOf(
                applicationContext.getString(R.string.notif_pill_title),
                applicationContext.getString(R.string.notif_pill_body),
                CHANNEL_PILL, 1003
            )
            else -> return Result.failure()
        }

        val intent = PendingIntent.getActivity(
            applicationContext, 0,
            Intent(applicationContext, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(applicationContext, channel as String)
            .setSmallIcon(R.drawable.ic_luna_moon)
            .setContentTitle(title as String)
            .setContentText(body as String)
            .setContentIntent(intent)
            .setAutoCancel(true)
            .build()

        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(id as Int, notif)

        // Re-schedule pill reminder for next day
        if (type == TYPE_PILL) {
            val prefs = applicationContext.getSharedPreferences("luna_prefs", Context.MODE_PRIVATE)
            val timeStr = prefs.getString("pill_reminder_time", null)
            if (timeStr != null) {
                val parts = timeStr.split(":").mapNotNull { it.toIntOrNull() }
                if (parts.size == 2) schedulePillReminder(applicationContext, parts[0], parts[1])
            }
        }

        return Result.success()
    }
}
