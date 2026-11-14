package com.example.my_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Shows the next prayer and a live countdown. The schedule (a week of prayer
 * instants) is written by Flutter, so the widget can advance to the next prayer
 * even when the app is not running. home_widget wakes this provider at each
 * prayer time.
 */
class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = parsePayload(widgetData.getString(PAYLOAD_KEY, null))
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                appWidgetId,
                buildViews(context, payload),
            )
        }
    }

    private fun buildViews(context: Context, payload: Payload): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
        views.setTextViewText(R.id.widget_location, payload.location)

        val next = payload.next
        if (next == null) {
            views.setTextViewText(R.id.widget_prayer_name, "Waktu shalat")
            views.setTextViewText(R.id.widget_prayer_time, "--:--")
            views.setTextViewText(R.id.widget_countdown_label, "Buka aplikasi")
            views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), null, false)
        } else {
            views.setTextViewText(R.id.widget_prayer_name, next.name)
            views.setTextViewText(R.id.widget_prayer_time, next.time)
            views.setTextViewText(R.id.widget_countdown_label, "menuju adzan")

            val remaining = (next.epochMs - System.currentTimeMillis()).coerceAtLeast(0L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                views.setChronometerCountDown(R.id.widget_countdown, true)
            }
            views.setChronometer(
                R.id.widget_countdown,
                SystemClock.elapsedRealtime() + remaining,
                null,
                true,
            )
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }
        return views
    }

    private fun parsePayload(raw: String?): Payload {
        if (raw.isNullOrBlank()) return Payload("Al-Qur'an", null)
        return try {
            val root = JSONObject(raw)
            val location = root.optString("location", "Al-Qur'an")
            val moments = root.optJSONArray("moments")
            val now = System.currentTimeMillis()
            var next: NextPrayer? = null
            if (moments != null) {
                for (index in 0 until moments.length()) {
                    val moment = moments.optJSONObject(index) ?: continue
                    val epoch = moment.optLong("epochMs", 0L)
                    if (epoch <= now) continue
                    next = NextPrayer(
                        name = moment.optString("label", "Shalat"),
                        time = moment.optString("time", "--:--"),
                        epochMs = epoch,
                    )
                    break
                }
            }
            Payload(location, next)
        } catch (_: Exception) {
            Payload("Al-Qur'an", null)
        }
    }

    private data class Payload(val location: String, val next: NextPrayer?)

    private data class NextPrayer(val name: String, val time: String, val epochMs: Long)

    companion object {
        private const val PAYLOAD_KEY = "prayer_widget_payload"
    }
}
