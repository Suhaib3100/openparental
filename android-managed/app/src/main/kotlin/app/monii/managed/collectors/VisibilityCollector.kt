package app.monii.managed.collectors

import android.content.Context
import app.monii.managed.enforcement.UsageTracker
import app.monii.managed.location.LocationReporter
import app.monii.managed.repo.MoniiRepository

/**
 * Periodic visibility, called from the Supervisor sync loop: report location each
 * cycle, buffer a full usage summary at most every 15 min, and screen-time totals.
 */
class VisibilityCollector(context: Context) {
    private val appContext = context.applicationContext
    private val usage = UsageTracker(appContext)
    private val location = LocationReporter(appContext)
    private val prefs =
        appContext.getSharedPreferences("monii_collector", Context.MODE_PRIVATE)

    suspend fun collect(repo: MoniiRepository) {
        location.reportLastKnown(repo)
        if (!summaryDue()) return

        val minutesByApp = usage.allTodayMinutes()
        if (minutesByApp.isNotEmpty()) {
            repo.bufferEvent("USAGE_SUMMARY", mapOf("minutesByApp" to minutesByApp))
            val total = minutesByApp.values.sum()
            repo.bufferEvent(
                "SCREEN_TIME",
                mapOf("totalMinutes" to total, "date" to java.time.LocalDate.now().toString()),
            )
        }
        prefs.edit().putLong("last_summary", System.currentTimeMillis()).apply()
    }

    private fun summaryDue(): Boolean {
        val last = prefs.getLong("last_summary", 0L)
        return System.currentTimeMillis() - last > 15 * 60 * 1000L
    }
}
