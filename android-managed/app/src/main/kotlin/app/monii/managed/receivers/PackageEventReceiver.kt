package app.monii.managed.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.monii.managed.identity.DeviceStore
import app.monii.managed.repo.MoniiRepository

/** New/removed app -> buffered as an event; synced and alertable by the backend. */
class PackageEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pkg = intent.data?.schemeSpecificPart ?: return
        if (pkg == context.packageName) return
        if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return

        val type = when (intent.action) {
            Intent.ACTION_PACKAGE_ADDED -> "APP_INSTALLED"
            Intent.ACTION_PACKAGE_REMOVED -> "APP_REMOVED"
            else -> return
        }
        val app = context.applicationContext
        val store = DeviceStore(app)
        if (!store.isPaired()) return
        MoniiRepository(app, store).bufferEvent(type, mapOf("package" to pkg))
    }
}
