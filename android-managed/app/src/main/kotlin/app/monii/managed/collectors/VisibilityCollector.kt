package app.monii.managed.collectors

import android.content.Context
import app.monii.managed.enforcement.PolicyRules
import app.monii.managed.enforcement.UsageTracker
import app.monii.managed.location.LocationReporter
import app.monii.managed.repo.MoniiRepository

/**
 * Periodic visibility, called from the Supervisor sync loop: report location each
 * cycle, and buffer a per-app usage summary at most every 15 min (throttled so we
 * don't spam events).
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

        val rules = PolicyRules.load(appContext)
        val watched = rules?.appLimits?.keys ?: emptySet()
        if (watched.isNotEmpty()) {
            val summary = watched.associateWith { usage.todayMinutes(it) }
            repo.bufferEvent("USAGE_SUMMARY", mapOf("minutesByApp" to summary))
        }
        prefs.edit().putLong("last_summary", System.currentTimeMillis()).apply()
    }

    private fun summaryDue(): Boolean {
        val last = prefs.getLong("last_summary", 0L)
        return System.currentTimeMillis() - last > 15 * 60 * 1000L
    }
}
