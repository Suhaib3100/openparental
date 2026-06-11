package app.monii.managed.supervisor

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import app.monii.managed.survival.SurvivalLog

/**
 * Periodic re-arm. WorkManager persists jobs across process death, so this runs
 * even after the OEM kills us. If the heartbeat has gone stale, restart the
 * service and record a WATCHDOG_RESTART — the count tells you how aggressively
 * this device kills background work.
 */
class WatchdogWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val last = SurvivalLog.lastHeartbeat(applicationContext)
        val stale = System.currentTimeMillis() - last > STALE_MS
        if (!SupervisorService.running || stale) {
            SurvivalLog.record(applicationContext, SurvivalLog.WATCHDOG, "stale=$stale")
            SupervisorService.start(applicationContext)
        }
        return Result.success()
    }

    companion object {
        // Heartbeat is 15s; allow a few minutes of slack before calling it dead.
        private const val STALE_MS = 3 * 60 * 1000L
    }
}
