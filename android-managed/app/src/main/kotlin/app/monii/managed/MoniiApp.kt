package app.monii.managed

import android.app.Application
import app.monii.managed.supervisor.WatchdogScheduler

class MoniiApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Re-arm the survival watchdog on every process start.
        WatchdogScheduler.schedule(this)
    }
}
