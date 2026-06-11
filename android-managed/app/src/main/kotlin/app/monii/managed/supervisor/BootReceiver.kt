package app.monii.managed.supervisor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.monii.managed.survival.SurvivalLog

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SurvivalLog.record(context, SurvivalLog.BOOT, intent.action ?: "")
        SupervisorService.start(context)
        WatchdogScheduler.schedule(context)
    }
}
