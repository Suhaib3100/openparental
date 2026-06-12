package app.monii.managed.accessibility

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import app.monii.managed.enforcement.EnforcementController
import app.monii.managed.identity.DeviceStore
import app.monii.managed.net.ContentItemDto
import app.monii.managed.repo.MoniiRepository
import java.time.Instant
import java.util.regex.Pattern

/**
 * Accessibility service: app-launch enforcement, foreground activity logging,
 * and disclosed browser URL capture for Browser Safety.
 */
class MonitorAccessibilityService : AccessibilityService() {

    private val enforcement by lazy { EnforcementController(this) }
    private var lastForegroundPkg: String? = null
    private var lastUrl: String? = null

    private val urlPattern = Pattern.compile("https?://\\S+", Pattern.CASE_INSENSITIVE)
    private val browserPackages = setOf(
        "com.android.chrome",
        "com.chrome.beta",
        "org.mozilla.firefox",
        "com.brave.browser",
        "com.opera.browser",
        "com.microsoft.emmx",
        "com.sec.android.app.sbrowser",
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val pkg = event.packageName?.toString() ?: return
                enforcement.onForegroundApp(pkg, this)
                logForeground(pkg)
                if (pkg in browserPackages) {
                    captureBrowserUrl(pkg)
                }
            }
        }
    }

    private fun logForeground(pkg: String) {
        if (pkg == packageName) return
        if (pkg == lastForegroundPkg) return
        lastForegroundPkg = pkg
        val store = DeviceStore(this)
        if (!store.isPaired()) return
        MoniiRepository(this, store).bufferEvent(
            "APP_FOREGROUND",
            mapOf(
                "package" to pkg,
                "action" to "foreground",
            ),
        )
    }

    private fun captureBrowserUrl(browserPkg: String) {
        val root = rootInActiveWindow ?: return
        val url = findUrl(root) ?: return
        if (url == lastUrl) return
        lastUrl = url
        val store = DeviceStore(this)
        if (!store.isPaired()) return
        MoniiRepository(this, store).bufferContent(
            ContentItemDto(
                source = "browser",
                counterparty = browserPkg,
                body = url,
                occurredAt = Instant.now().toString(),
            ),
        )
    }

    private fun findUrl(node: AccessibilityNodeInfo): String? {
        val text = node.text?.toString()
        if (!text.isNullOrBlank()) {
            val m = urlPattern.matcher(text)
            if (m.find()) return m.group()
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findUrl(child)
            child.recycle()
            if (found != null) return found
        }
        return null
    }

    override fun onInterrupt() {
        // no-op
    }
}
