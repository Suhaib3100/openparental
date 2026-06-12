package app.monii.managed

import android.app.Application
import app.monii.managed.supervisor.WatchdogScheduler
import app.monii.managed.sync.SyncScheduler

class MoniiApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Re-arm the survival watchdog and the backend sync on every process start.
        WatchdogScheduler.schedule(this)
        SyncScheduler.schedule(this)
    }
}
