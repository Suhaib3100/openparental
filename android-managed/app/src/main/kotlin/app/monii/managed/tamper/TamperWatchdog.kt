package app.monii.managed.tamper

import android.content.Context
import android.os.PowerManager
import app.monii.managed.admin.AdminManager
import app.monii.managed.permissions.SpecialAccess
import app.monii.managed.repo.MoniiRepository

/**
 * On-device half of the tamper engine: each cycle, snapshot the enforcement
 * layers and report the moment one flips on->off. Force-stop / OEM-kill cannot be
 * caught here (the process is dead) — the server heartbeat reconciler covers that.
 */
class TamperWatchdog(private val context: Context) {
    private val prefs = context.getSharedPreferences("monii_tamper", Context.MODE_PRIVATE)
    private val admin = AdminManager(context)

    suspend fun check(repo: MoniiRepository) {
        evaluate("ACCESSIBILITY_OFF", SpecialAccess.isAccessibilityEnabled(context), repo)
        evaluate("ADMIN_OFF", admin.isActive(), repo)
        evaluate("BATTERY_OPT_OFF", isIgnoringBatteryOpt(), repo)
    }

    private suspend fun evaluate(kind: String, currentlyOn: Boolean, repo: MoniiRepository) {
        val key = "on_$kind"
        // first run: seed with the current value so we don't report a phantom drop
        val wasOn = prefs.getBoolean(key, currentlyOn)
        if (wasOn && !currentlyOn) {
            runCatching { repo.reportTamper(kind, "layer disabled on device") }
        }
        prefs.edit().putBoolean(key, currentlyOn).apply()
    }

    private fun isIgnoringBatteryOpt(): Boolean {
        val pm = context.getSystemService(PowerManager::class.java) ?: return true
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }
}
