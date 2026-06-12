package app.monii.managed.enforcement

import android.accessibilityservice.AccessibilityService
import android.content.Context

/**
 * Decides whether the foreground app should be blocked and, if so, bounces the
 * user home. Block reasons: explicit block list, an active blocking schedule
 * (bedtime/school), or a per-app daily time limit exceeded.
 *
 * Honest limit (from the eng review): GLOBAL_ACTION_HOME is racy and a fast
 * switcher can flash the app for a moment. The VPN layer (Phase 6) is the
 * harder-to-dodge backstop; this is the responsive first line.
 */
class EnforcementController(context: Context) {
    private val appContext = context.applicationContext
    private val usage = UsageTracker(appContext)

    fun onForegroundApp(pkg: String, service: AccessibilityService) {
        if (pkg == appContext.packageName) return // never block ourselves
        val rules = PolicyRules.load(appContext) ?: return
        if (shouldBlock(pkg, rules)) {
            service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
        }
    }

    private fun shouldBlock(pkg: String, rules: PolicyRules): Boolean {
        if (pkg in rules.blockedApps) return true
        if (rules.isWithinBlockingSchedule()) return true
        val limit = rules.appLimits[pkg]
        if (limit != null && usage.todayMinutes(pkg) >= limit) return true
        return false
    }
}
