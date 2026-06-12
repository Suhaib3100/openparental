package app.monii.managed.permissions

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import app.monii.managed.accessibility.MonitorAccessibilityService

/** Checks + deep-link intents for the special-access permissions used in onboarding. */
object SpecialAccess {

    fun isAccessibilityEnabled(context: Context): Boolean {
        val expected = ComponentName(context, MonitorAccessibilityService::class.java)
            .flattenToString()
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }

    fun isUsageAccessGranted(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        @Suppress("DEPRECATION")
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun accessibilitySettingsIntent(): Intent =
        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)

    fun usageAccessSettingsIntent(): Intent =
        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
}
