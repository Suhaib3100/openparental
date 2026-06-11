package app.monii.managed.survival

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Single source of truth for the survival spike's telemetry.
 *
 *   service start ──► record(START)      heartbeat (15s) ──► heartbeat()
 *   boot/replaced ──► record(BOOT)       watchdog (15m)  ──► record(WATCHDOG) if stale
 *   destroyed     ──► record(DESTROY)
 *
 * Counters live in SharedPreferences (cheap, survives process death). A
 * human-readable timeline is appended to filesDir/survival_log.txt, so after the
 * device sits overnight you can read exactly when it died and what brought it back.
 */
object SurvivalLog {
    private const val PREFS = "monii_survival"
    private const val LOG_FILE = "survival_log.txt"
    private const val MAX_LOG_BYTES = 256 * 1024

    const val START = "SERVICE_START"
    const val DESTROY = "SERVICE_DESTROY"
    const val TASK_REMOVED = "TASK_REMOVED"
    const val BOOT = "BOOT"
    const val WATCHDOG = "WATCHDOG_RESTART"

    private val fmt = SimpleDateFormat("MM-dd HH:mm:ss", Locale.US)

    fun record(context: Context, event: String, detail: String = "") {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        prefs.edit().apply {
            when (event) {
                START -> {
                    putLong("service_start_at", now)
                    putInt("start_count", prefs.getInt("start_count", 0) + 1)
                    if (!prefs.contains("first_start_at")) putLong("first_start_at", now)
                }
                BOOT -> putInt("boot_count", prefs.getInt("boot_count", 0) + 1)
                WATCHDOG -> putInt("watchdog_count", prefs.getInt("watchdog_count", 0) + 1)
            }
            apply()
        }
        append(context, "$event $detail".trim())
    }

    fun heartbeat(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong("last_heartbeat_at", System.currentTimeMillis()).apply()
    }

    fun lastHeartbeat(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong("last_heartbeat_at", 0L)

    fun snapshot(context: Context): Stats {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return Stats(
            firstStartAt = p.getLong("first_start_at", 0L),
            serviceStartAt = p.getLong("service_start_at", 0L),
            lastHeartbeatAt = p.getLong("last_heartbeat_at", 0L),
            startCount = p.getInt("start_count", 0),
            bootCount = p.getInt("boot_count", 0),
            watchdogCount = p.getInt("watchdog_count", 0),
        )
    }

    fun tail(context: Context, maxLines: Int = 40): String {
        val f = File(context.filesDir, LOG_FILE)
        if (!f.exists()) return "(no events yet)"
        return f.readLines().takeLast(maxLines).reversed().joinToString("\n")
    }

    @Synchronized
    private fun append(context: Context, line: String) {
        val f = File(context.filesDir, LOG_FILE)
        if (f.exists() && f.length() > MAX_LOG_BYTES) {
            val kept = f.readLines().takeLast(500)
            f.writeText(kept.joinToString("\n") + "\n")
        }
        f.appendText("${fmt.format(Date())}  $line\n")
    }

    data class Stats(
        val firstStartAt: Long,
        val serviceStartAt: Long,
        val lastHeartbeatAt: Long,
        val startCount: Int,
        val bootCount: Int,
        val watchdogCount: Int,
    )
}
