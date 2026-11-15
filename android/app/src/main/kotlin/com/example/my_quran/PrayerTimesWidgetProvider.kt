package com.example.my_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * Shows the five daily prayers, highlights the upcoming one with a live
 * countdown and prints the Hijri date. Flutter writes a week of prayer instants
 * (plus a preformatted Hijri date) so the widget keeps working while the app is
 * closed; home_widget wakes this provider at each prayer time.
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

        val now = System.currentTimeMillis()
        // Before today's Fajr the same day still applies; after Isya this moves
        // to tomorrow so the row and the highlighted prayer stay consistent.
        val today = payload.days.firstOrNull { day ->
            (day.prayers.lastOrNull()?.epochMs ?: 0L) > now
        } ?: payload.days.lastOrNull()
        val prayers = today?.prayers ?: payload.moments.take(5)
        // A stale payload (app not opened for over a week) must not advertise a
        // prayer in the past; show the refresh prompt instead.
        val next = payload.moments.firstOrNull { it.epochMs > now }

        val hijri = today?.hijri?.takeIf { it.isNotBlank() }
            ?: payload.hijri.takeIf { it.isNotBlank() }
            ?: "Kalender Hijriah"
        views.setTextViewText(R.id.widget_hijri, hijri)
        renderNext(views, next)
        renderPrayerRow(views, prayers, next)

        // Runs the Dart entry point in a background isolate. It recomputes the
        // schedule from the coordinates saved in the payload, so the refresh
        // button works even when the app has not been opened recently.
        views.setOnClickPendingIntent(
            R.id.widget_refresh,
            HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("myquran://prayer-widget/refresh"),
            ),
        )

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

    private fun renderNext(views: RemoteViews, next: PrayerTime?) {
        if (next == null) {
            // Loading/fallback state: keep every label visible instead of
            // drawing an apparently blank widget when the payload is empty.
            views.setTextViewText(R.id.widget_prayer_name, "Memuat jadwal")
            views.setTextViewText(R.id.widget_prayer_time, "--:--")
            views.setTextViewText(
                R.id.widget_countdown_label,
                "Buka aplikasi atau ketuk ⟳",
            )
            views.setViewVisibility(R.id.widget_countdown, View.GONE)
            return
        }

        views.setTextViewText(R.id.widget_prayer_name, next.label)
        views.setTextViewText(R.id.widget_prayer_time, next.time)
        views.setTextViewText(R.id.widget_countdown_label, "menuju adzan")
        views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)

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

    private fun renderPrayerRow(
        views: RemoteViews,
        prayers: List<PrayerTime>,
        next: PrayerTime?,
    ) {
        for ((key, column) in COLUMNS) {
            val moment = prayers.firstOrNull { it.prayer == key }
            val isNext = next?.prayer == key && next.epochMs == moment?.epochMs

            views.setTextViewText(column.nameId, moment?.label ?: column.fallback)
            views.setTextViewText(column.timeId, moment?.time ?: "--:--")
            views.setInt(
                column.cellId,
                "setBackgroundColor",
                if (isNext) HIGHLIGHT_COLOR else 0,
            )
            views.setInt(
                column.nameId,
                "setTextColor",
                if (isNext) NEXT_COLOR else MUTED_COLOR,
            )
            views.setInt(
                column.timeId,
                "setTextColor",
                if (isNext) NEXT_COLOR else TEXT_COLOR,
            )
            views.setTextViewTextSize(
                column.timeId,
                TypedValue.COMPLEX_UNIT_SP,
                if (isNext) 13f else 12f,
            )
        }
    }

    private fun parsePayload(raw: String?): Payload {
        if (raw.isNullOrBlank()) return emptyPayload()
        return try {
            val root = JSONObject(raw)
            val moments = parsePrayers(root.optJSONArray("moments"))
            val rawDays = root.optJSONArray("days")
            val days = mutableListOf<PrayerDay>()
            if (rawDays != null) {
                for (index in 0 until rawDays.length()) {
                    val day = rawDays.optJSONObject(index) ?: continue
                    val prayers = parsePrayers(day.optJSONArray("prayers"))
                    if (prayers.isNotEmpty()) {
                        days.add(
                            PrayerDay(
                                hijri = day.optString("hijriDate", ""),
                                prayers = prayers,
                            ),
                        )
                    }
                }
            }
            Payload(
                location = root.optString("location", "Al-Qur'an")
                    .takeIf { it.isNotBlank() } ?: "Al-Qur'an",
                hijri = root.optString("hijriDate", ""),
                days = days,
                moments = moments,
            )
        } catch (_: Exception) {
            emptyPayload()
        }
    }

    private fun parsePrayers(array: JSONArray?): List<PrayerTime> {
        if (array == null) return emptyList()
        val result = mutableListOf<PrayerTime>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val epoch = item.optLong("epochMs", 0L)
            if (epoch <= 0L) continue
            result.add(
                PrayerTime(
                    prayer = item.optString("prayer", ""),
                    label = item.optString("label", "Shalat"),
                    time = item.optString("time", "--:--"),
                    epochMs = epoch,
                ),
            )
        }
        return result
    }

    private fun emptyPayload() = Payload(
        location = "Al-Qur'an",
        hijri = "Kalender Hijriah",
        days = emptyList(),
        moments = emptyList(),
    )

    private data class PrayerTime(
        val prayer: String,
        val label: String,
        val time: String,
        val epochMs: Long,
    )

    private data class PrayerDay(val hijri: String, val prayers: List<PrayerTime>)

    private data class Payload(
        val location: String,
        val hijri: String,
        val days: List<PrayerDay>,
        val moments: List<PrayerTime>,
    )

    private data class Column(
        val cellId: Int,
        val nameId: Int,
        val timeId: Int,
        val fallback: String,
    )

    companion object {
        private const val PAYLOAD_KEY = "prayer_widget_payload"
        private const val HIGHLIGHT_COLOR = 0x33C9A227
        private const val NEXT_COLOR = 0xFFF0D48A.toInt()
        private const val MUTED_COLOR = 0xFFB9DED4.toInt()
        private const val TEXT_COLOR = 0xFFFFFBF1.toInt()

        private val COLUMNS = linkedMapOf(
            "fajr" to Column(
                R.id.widget_fajr_cell,
                R.id.widget_fajr_name,
                R.id.widget_fajr_time,
                "Subuh",
            ),
            "dhuhr" to Column(
                R.id.widget_dhuhr_cell,
                R.id.widget_dhuhr_name,
                R.id.widget_dhuhr_time,
                "Dzuhur",
            ),
            "asr" to Column(
                R.id.widget_asr_cell,
                R.id.widget_asr_name,
                R.id.widget_asr_time,
                "Ashar",
            ),
            "maghrib" to Column(
                R.id.widget_maghrib_cell,
                R.id.widget_maghrib_name,
                R.id.widget_maghrib_time,
                "Maghrib",
            ),
            "isha" to Column(
                R.id.widget_isha_cell,
                R.id.widget_isha_name,
                R.id.widget_isha_time,
                "Isya",
            ),
        )
    }
}
