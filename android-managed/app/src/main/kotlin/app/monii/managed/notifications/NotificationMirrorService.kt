package app.monii.managed.notifications

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import app.monii.managed.identity.DeviceStore
import app.monii.managed.net.ContentItemDto
import app.monii.managed.repo.MoniiRepository
import java.time.Instant

/**
 * Mirrors posted notifications to the content archive (source=notification) so
 * parents can review them on the Notice tab. The child sees this permission in
 * Settings and in Check Permissions.
 */
class NotificationMirrorService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val store = DeviceStore(this)
        if (!store.isPaired()) return
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        if (title.isBlank() && text.isBlank()) return
        val body = listOf(title, text).filter { it.isNotBlank() }.joinToString(" — ")
        MoniiRepository(this, store).bufferContent(
            ContentItemDto(
                source = "notification",
                counterparty = pkg,
                body = body,
                occurredAt = Instant.now().toString(),
            ),
        )
    }
}
