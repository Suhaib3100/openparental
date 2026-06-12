package app.monii.managed.collectors

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.Manifest
import androidx.core.content.ContextCompat
import app.monii.managed.admin.AdminManager
import app.monii.managed.permissions.SpecialAccess
import app.monii.managed.repo.MoniiRepository
import app.monii.managed.vpn.VpnFilterService

/** Snapshot of high-risk permissions — synced to parent via PERMISSION_STATE events. */
class PermissionCollector(private val context: Context) {
    private val prefs =
        context.applicationContext.getSharedPreferences("monii_collector", Context.MODE_PRIVATE)

    fun collectIfDue(repo: MoniiRepository) {
        if (!due()) return
        val appContext = context.applicationContext
        val permissions = mapOf(
            "location" to hasLocation(appContext),
            "notifications" to SpecialAccess.isNotificationListenerEnabled(appContext),
            "usageStats" to SpecialAccess.isUsageAccessGranted(appContext),
            "accessibility" to SpecialAccess.isAccessibilityEnabled(appContext),
            "deviceAdmin" to AdminManager(appContext).isActive(),
            "screenCapture" to false,
            "microphone" to hasMic(appContext),
            "vpn" to VpnFilterService.isRunning(appContext),
        )
        repo.bufferEvent("PERMISSION_STATE", mapOf("permissions" to permissions))
        prefs.edit().putLong("last_permissions", System.currentTimeMillis()).apply()
    }

    private fun due(): Boolean {
        val last = prefs.getLong("last_permissions", 0L)
        return System.currentTimeMillis() - last > 5 * 60 * 1000L
    }

    private fun hasLocation(ctx: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            ctx,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            ctx,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun hasMic(ctx: Context): Boolean =
        ContextCompat.checkSelfPermission(
            ctx,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
}

/** Daily launcher-app inventory so the parent can list installed apps. */
class InstalledAppsCollector(private val context: Context) {
    private val prefs =
        context.applicationContext.getSharedPreferences("monii_collector", Context.MODE_PRIVATE)

    fun snapshotIfDue(repo: MoniiRepository) {
        if (!due()) return
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(intent, 0)
        for (ri in activities) {
            val pkg = ri.activityInfo.packageName
            if (pkg == context.packageName) continue
            val label = ri.loadLabel(pm).toString()
            repo.bufferEvent(
                "APP_INSTALLED",
                mapOf("package" to pkg, "label" to label, "snapshot" to true),
            )
        }
        prefs.edit().putLong("last_inventory", System.currentTimeMillis()).apply()
    }

    private fun due(): Boolean {
        val last = prefs.getLong("last_inventory", 0L)
        return System.currentTimeMillis() - last > 24 * 60 * 60 * 1000L
    }
}
