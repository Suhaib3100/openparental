package app.monii.managed.accessibility

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import app.monii.managed.enforcement.EnforcementController

/**
 * The load-bearing accessibility service. v1 uses it for app-launch enforcement;
 * Phase 6 extends it to read browser URLs (web safety) and AMBER keyword/history.
 */
class MonitorAccessibilityService : AccessibilityService() {

    private val enforcement by lazy { EnforcementController(this) }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        enforcement.onForegroundApp(pkg, this)
    }

    override fun onInterrupt() {
        // no-op
    }
}
