package app.monii.managed

import android.app.Application
import app.monii.managed.identity.DeviceStore
import app.monii.managed.supervisor.WatchdogScheduler
import app.monii.managed.sync.SyncScheduler
import com.google.firebase.messaging.FirebaseMessaging

class MoniiApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Re-arm the survival watchdog and the backend sync on every process start.
        WatchdogScheduler.schedule(this)
        SyncScheduler.schedule(this)
        // Fetch the FCM token early so it can be registered with the backend.
        runCatching {
            FirebaseMessaging.getInstance().token.addOnSuccessListener { token ->
                DeviceStore(this).setFcmToken(token)
            }
        }
    }
}
