package app.monii.managed.admin

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import app.monii.managed.identity.DeviceStore
import app.monii.managed.repo.MoniiRepository
import app.monii.managed.survival.SurvivalLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MoniiDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        SurvivalLog.record(context, "ADMIN_DISABLED")
        // Admin removed = tamper. Report best-effort; the server heartbeat
        // reconciler is the backstop if this push doesn't land.
        val pending = goAsync()
        val app = context.applicationContext
        CoroutineScope(Dispatchers.IO).launch {
            try {
                MoniiRepository(app, DeviceStore(app))
                    .reportTamper("ADMIN_OFF", "device admin removed")
            } catch (_: Exception) {
                // swallow — backstop covers it
            } finally {
                pending.finish()
            }
        }
    }
}
