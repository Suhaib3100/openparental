package app.monii.managed.fcm

import app.monii.managed.identity.DeviceStore
import app.monii.managed.sync.SyncScheduler
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Receives high-priority data messages from the backend. We don't act on the
 * payload directly — we just trigger an immediate sync, so the device pulls and
 * executes whatever command is waiting (idempotent on the server). Also keeps the
 * device's FCM token registered.
 */
class MoniiFcmService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        DeviceStore(applicationContext).setFcmToken(token)
        SyncScheduler.runOnce(applicationContext)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        SyncScheduler.runOnce(applicationContext)
    }
}
