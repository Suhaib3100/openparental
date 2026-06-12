package app.monii.managed.enforcement

import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

/** Per-app foreground minutes today, via UsageStats (needs Usage Access granted). */
class UsageTracker(private val context: Context) {
    private val usm =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    fun todayMinutes(pkg: String): Int {
        val manager = usm ?: return 0
        val stats = manager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startOfDay(),
            System.currentTimeMillis(),
        )
        val total = stats
            ?.filter { it.packageName == pkg }
            ?.sumOf { it.totalTimeInForeground } ?: 0L
        return (total / 60_000L).toInt()
    }

    private fun startOfDay(): Long {
        val c = Calendar.getInstance()
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }
}
