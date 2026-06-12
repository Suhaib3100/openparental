package app.monii.managed.enforcement

import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

/** Per-app foreground minutes today, via UsageStats (needs Usage Access granted). */
class UsageTracker(private val context: Context) {
    private val usm =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    fun todayMinutes(pkg: String): Int =
        allTodayMinutes()[pkg] ?: 0

    /** All user apps with non-zero foreground time today. */
    fun allTodayMinutes(): Map<String, Int> {
        val manager = usm ?: return emptyMap()
        val stats = manager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startOfDay(),
            System.currentTimeMillis(),
        ) ?: return emptyMap()
        return stats
            .filter { it.totalTimeInForeground > 0 }
            .associate { it.packageName to (it.totalTimeInForeground / 60_000L).toInt() }
            .filterValues { it > 0 }
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
